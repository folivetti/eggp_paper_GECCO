module TinyGP



# TODO 
# - postfix instead of prefix
# - likelihoods (probably via abstract type)
# - dl
# - likelihood parameters. an individual should also include the likelihood parameters (at the root level). They should be optimized
# - symbols: neg, inv, aq, sin, cos, tanh, ...
# - Test speedup / accuracy with Float32


using TimerOutputs
using Random
using Printf
using Optim # gradient-based optimization of parameters
using PreallocationTools 
using DelimitedFiles

# TODO check if this has an effect (probably not since the docs mention that we would have to reload ForwardDiff)
using ForwardDiff, Preferences
set_preferences!(ForwardDiff, "nansafe_mode" => true) 

using LinearAlgebra # for svd in DL

struct Instruction 
    opcode::UInt8
    val::Float32
end
Instruction(opcode) = Instruction(opcode, 0.0f0)

const ADD::UInt8 = 110
const SUB::UInt8 = 111
const MUL::UInt8 = 112
const DIV::UInt8 = 113
const EXP::UInt8 = 114
const LOGABS::UInt8 = 115 # log |x|
const POWABS::UInt8 = 116 # |x|^y
const PARAM::UInt8 = 117
const FSET_START::UInt8 = ADD
const FSET_END::UInt8 = POWABS

const ARITY = Dict(ADD => 2,
    SUB => 2,
    MUL => 2,
    DIV => 2,
    POWABS => 2,
    EXP => 1,
    LOGABS => 1, 
    PARAM => 0)

# Default parameter values
const MAX_LEN = 100
const POPSIZE = 10_000
const DEPTH = 5
const GENERATIONS = 100
const TSIZE = 2
const PMUT_PER_NODE = 0.05
const CROSSOVER_PROB = 0.9 # (1 - CROSSOVER_PROB) individuals are mutated, and each node has PMUT_PER_NODE probability

mutable struct Algorithm{T,F1,F2}
    const fitness::Vector{T}
    const pop::Vector{Vector{Instruction}}
    const X::Matrix{T}
    const y::Vector{T}
    fbestpop::T
    favgpop::T
    avg_len::T
    fevals::Int64
    const seed::Int64
    const generations::Int32
    const maxlen::Int32
    const tournamentsize::Int32
    const to::TimerOutput
    const print_trace::Bool
    const paramopt_loss_func::F1
    const loss_func::F2
end

varnumber(gp) = size(gp.X, 2)

function Algorithm{T}(fname::AbstractString, targetname; 
    seed=-1, generations=GENERATIONS, popsize=POPSIZE, 
    maxlen=MAX_LEN, tournamentsize=TSIZE, print_trace=false, 
    paramopt_loss_func::F1 = mean_squared_error, loss_func::F2 = mean_squared_error) where {T <: AbstractFloat, F1,F2}
    seed >= 0 && seed!(seed)
    
    X, y = load_dataset(T, fname, targetname)
    
    varnumber = size(X, 2)
    varnumber < FSET_START || error("too many variables")
    
    fitness = Vector{T}(undef, popsize)
    pop = Vector{Vector{Instruction}}(undef, popsize)
    
    gp = Algorithm{T,F1,F2}(fitness, pop, X, y, 0.0, 0.0, 0.0, 0, seed, generations, maxlen, 
        tournamentsize, TimerOutput(), print_trace, 
        paramopt_loss_func, loss_func)
    
    print_parms(gp)
   
    return gp
end

# pre-allocated of buffers for fitness evaluation in a thread
struct InterpreterBuffers{T,DV,DM}
    x_buffer::Matrix{T}
    ypred_buffer::DV # DiffCache Vector
    stack_buffer::DM # DiffCache Matrix
    batchsize::Int64
    symfreq::Dict{UInt8, Int32} # for calculating function complexity
end
batchsize(buffers::InterpreterBuffers) = buffers.batchsize

function InterpreterBuffers(::Type{T}, numobs, numvars, max_stack_size, batchsize=1024) where {T}
    x_buffer = Matrix{T}(undef, batchsize, numvars)
    max_chunk_size = 4
    ypred_buffer = DiffCache(Vector{T}(undef, numobs), max_chunk_size, levels=2)
    stack_buffer = DiffCache(Matrix{T}(undef, batchsize, max_stack_size), max_chunk_size, levels=2)
    sym_freq = Dict{UInt8, Int32}() # for calculating function complexity
    InterpreterBuffers(x_buffer, ypred_buffer, stack_buffer, batchsize, sym_freq)
end

# all columns except for the target are allowed input
function load_dataset(::Type{T}, filename::AbstractString, targetname) where {T <: AbstractFloat}
    data,varnames = readdlm(filename, ',', T, header=true)
    
    targetidx = findfirst((==)(targetname), varnames[1, :])
    isnothing(targetidx) && error("Could not find variable $targetname in $filename (with varnames: $varnames)")
    
    X = data[:, setdiff(1:end, targetidx)]
    y = data[:, targetidx]
    X, y
end

# returns end of subexpression starting at pos
# optional update action allows to modify instructions while traversing
function traverse(buffer, pos; update=identity)
    buffer[pos] = update(buffer[pos])

    primitive = buffer[pos].opcode
    if primitive < FSET_START
        return pos
    elseif primitive == PARAM
        return pos
    elseif ARITY[primitive] == 1
        traverse(buffer, pos + 1, update = update)
    elseif ARITY[primitive] == 2
        nextpos = traverse(buffer, pos + 1, update = update)
        return traverse(buffer, nextpos + 1, update = update)
    end
end

function grow!(buffer, maxlen, depth, numvars)
    if length(buffer) >= maxlen
        empty!(buffer) # over size limit, clear buffer to indicate failure
        return buffer
    end
    
    prim = isempty(buffer) ? 1 : rand(0:1)  # terminal or function but force terminal on first position
    if prim == 0 || depth == 0
        # random value initial value ~ N(0,1) for the terminal node (ineffective for variables)
        randval = randn(Float32)
        if rand() < 0.5
            varCode = rand(1:numvars)
            push!(buffer, Instruction(UInt8(varCode), randval))
        else
            push!(buffer, Instruction(UInt8(PARAM), randval))
        end
    else
        func = UInt8(rand(FSET_START:FSET_END))
        push!(buffer, Instruction(func))
        grow!(buffer, maxlen, depth - 1, numvars)
        ARITY[func] == 1 && return buffer # unary functions
        
        # binary functions
        grow!(buffer, maxlen, depth - 1, numvars)
    end
end

function create_random_indiv(gp, depth)
    buffer = Instruction[]; sizehint!(buffer, gp.maxlen + 1)
    while isempty(buffer)
        grow!(buffer, gp.maxlen, depth, varnumber(gp))
    end

    @assert length(buffer) == traverse(buffer, 1)
    
    buffer
end


function extractparam(::Type{T}, prog) where {T}
    param = T[]

    function extract(instruction)
        if instruction.opcode == PARAM
            push!(param, instruction.val)
        end
        instruction
    end

    traverse(prog, 1, update = extract)

    param
end

function updateparam!(prog, param)
    paramidx = 0
    function updateval(instruction)
        if instruction.opcode == PARAM
            paramidx += 1
            return Instruction(PARAM, param[paramidx])
        end
        instruction # unchanged
    end

    traverse(prog, 1, update = updateval)

    param
end

pdiv(a,b) = iszero(b) ? zero(a) : a / b

function run_program(prog, x, param, stack)
    pc = length(prog)
    paramidx = length(param)
    sp = 0
    while pc > 0
        @inbounds primitive = prog[pc].opcode
        if primitive < FSET_START
            sp += 1
            @simd for i in axes(stack)[1] @inbounds stack[i, sp] = x[i, primitive] end
        elseif primitive == PARAM
            sp += 1
            @assert paramidx > 0 && paramidx <= length(param) "$(param) $(prog) $(tostring(prog))"
            @simd for i in axes(stack)[1] @inbounds stack[i, sp] = param[paramidx] end
            paramidx -= 1
        elseif primitive == ADD
            @simd for i in axes(stack)[1] @inbounds stack[i, sp - 1] = stack[i, sp] + stack[i, sp - 1] end
            sp -= 1
        elseif primitive == SUB
            @simd for i in axes(stack)[1] @inbounds stack[i, sp - 1] = stack[i, sp] - stack[i, sp - 1] end
            sp -= 1
        elseif primitive == MUL
            @simd for i in axes(stack)[1] @inbounds stack[i, sp - 1] = stack[i, sp] * stack[i, sp - 1] end
            sp -= 1
        elseif primitive == DIV
            @simd for i in axes(stack)[1] @inbounds stack[i, sp - 1] = pdiv(stack[i, sp], stack[i, sp - 1]) end
            sp -= 1
        elseif primitive == EXP
            @simd for i in axes(stack)[1] @inbounds stack[i, sp] = exp(stack[i, sp]) end
        elseif primitive == LOGABS
            @simd for i in axes(stack)[1] @inbounds stack[i, sp] = log(abs(stack[i, sp])) end
        elseif primitive == POWABS
            @simd for i in axes(stack)[1] @inbounds stack[i, sp - 1] = abs(stack[i, sp]) ^ stack[i, sp - 1] end
        else
            error("unknown operator $primitive")
        end
        pc -= 1
    end
    @view stack[:, 1]
end


# simple interface to predict the output of a program for a dataset X
function predict(prog, X) 
    p = extractparam(eltype(X), prog)
    numobs = size(X, 1)
    numvars = size(X, 2)

    predict!(InterpreterBuffers(eltype(X), numobs, numvars, length(prog)), prog, X, p)
end

# predict with parameter values explicitly given
# uses pre-allocated buffers
function predict!(buffers::InterpreterBuffers, prog, X, p)
    T = eltype(p)
    ypred = get_tmp(buffers.ypred_buffer, T)
    stack = get_tmp(buffers.stack_buffer, T)
    x_buffer = buffers.x_buffer

    r1 = axes(X, 1)
    r2 = axes(X, 2)

    # Use Iterators.partition to handle batching, including the last partial batch
    for batch in Iterators.partition(r1, batchsize(buffers))
        copyto!(x_buffer, 1:length(batch), r2, 'N', X, batch, r2)
        res = run_program(prog, x_buffer, p, stack)
        copyto!(ypred, batch[1], res, 1, length(batch))
    end
    
    ypred
end


# TODO not true for now
# Probably need to introduce a likelihood + model class
# All loss functions have the interface (y, ypred::AbstractArray{T}, prog::Union{Nothing,Vector{Instruction}})::T where {T}.
# The third parameter is the program represented in prefix form and can be used to calculate a program complexity penality
# as demonstrated in the description_length() loss function.
# The loss functions are allowed to update the program e.g. to optimize parameters or even to simplify expressions.

function mean_squared_error(y,ypred)
    @assert axes(ypred) == axes(y)
    sumsq = zero(eltype(ypred))
    @inbounds for i in eachindex(y)
        sumsq += (ypred[i] - y[i])^2
    end
    sumsq / length(y)
end

function mean_squared_error(param, prog, gp, buffers)
    ypred = predict!(buffers, prog, gp.X, param)
    mean_squared_error(gp.y, ypred)
end

function r2_score(y, ypred)
    @assert axes(ypred) == axes(y)
    mean_y = sum(y) / length(y)
    ss_tot = zero(eltype(ypred))
    ss_res = zero(eltype(ypred))
    @inbounds for i in eachindex(y)
        ss_res += (ypred[i] - y[i])^2
        ss_tot += (y[i] - mean_y)^2
    end

    iszero(ss_tot) ? one(eltype(ypred)) : one(eltype(ypred)) - ss_res / ss_tot
end

function r2_score(param, prog, gp, buffers)
    ypred = predict!(buffers, prog, gp.X, param)
    r2_score(gp.y, ypred)
end

# for Gaussian likelihood with fixed noise variance σ²_err = empirical MSE
function negloglik(y, ypred)
    n = length(y)
    T = eltype(ypred)
    # TODO σ2_err should be a user-specified parameter or optimized as well
    sumsq = zero(T)
    for i in eachindex(y)
        sumsq += (ypred[i] - y[i])^2
    end
    σ2_err = sumsq / n
    nll = T(1/2) * (n * log(T(2 * pi) * σ2_err) + sumsq / σ2_err)
    (isnan(nll) || isinf(nll)) && return floatmax(T)
    nll
end

function negloglik(param, prog, gp, buffers)
    ypred = predict!(buffers, prog, gp.X, param)
    negloglik(gp.y, ypred)
end

function description_length(param, prog, gp, buffers)
    T = eltype(param)
    p_compl = param_compl(param, prog, gp, buffers) # this potentially updates the parameters
    p_compl == floatmax(T) && return p_compl

    f_compl = func_compl(prog, buffers.symfreq)
    negloglik(param, prog, gp, buffers) + T(f_compl) + p_compl
end

function func_compl(prog, symfreq)
    empty!(symfreq)
    # different variables are different symbols, parameters are all the same symbol
    for i in eachindex(prog)
        curval = get!(symfreq, prog[i].opcode, 0)
        symfreq[prog[i].opcode] = curval + 1
    end
    sum(values(symfreq)) * log(length(symfreq)) # length * sym_code_length
end

# only allow chunk sizes up to 4 (we don't want to compile predict for many different chunk sizes)
get_chunk(p) = ForwardDiff.Chunk{min(length(p),4)}()

function param_compl(param, prog, gp, buffers)
    T = eltype(param)    

    length(param) == 0 && return zero(T)

    # make sure we are at a local optimum
    loss = (p) -> negloglik(p, prog, gp, buffers)

    gradCfg = ForwardDiff.GradientConfig(loss, param, get_chunk(param))
    grad! = (g,p) -> ForwardDiff.gradient!(g, loss, p, gradCfg)
    try
        res = Optim.optimize(loss, grad!, param, LBFGS(), Optim.Options(f_abstol=1e-4, f_reltol=1e-8)) # TODO tunable iterations
        # println(res)
        if Optim.converged(res)
            param .= Optim.minimizer(res)
            updateparam!(prog, param)
        else
            return floatmax(T)
        end
    catch ex
        @warn ex
        return floatmax(T)
    end
    
    hessianCfg = ForwardDiff.HessianConfig(loss, param, get_chunk(param))
    fim = ForwardDiff.hessian(loss, param, hessianCfg)::Matrix{T}
    
    any(isnan, fim) && return floatmax(T)

    # clean up numerical errors
    fim = T(1/2) .* (fim .+ fim')
    
    # calculate parameter complexity in rotated space
    fim_fact = svd(fim)
    param_proj = (fim_fact.Vt * param)
    
    prec = fim_fact.S
    # prevent negative contribution by uncertain parameters abs|p| / sqrt(12/prec) < 1
    p_compl = zero(T)
    @inbounds for i in eachindex(param_proj)
        pi_compl = T(1/2) * (log(prec[i]) - T(log(3))) + log(abs(param_proj[i]))
        p_compl += max(zero(T), pi_compl)
    end
    p_compl
end

# optimizes parameters and updates the prog and p0 if successful
# returns the number of function evaluations
# must not make changes to gp (thread-safety)
function optimize!(prog, p0, buffers, gp)
    fevals = 0

    function loss(p)
        val = gp.paramopt_loss_func(p, prog, gp, buffers) # TODO cleanup interface
        (isnan(val) || isinf(val)) && return floatmax(val)

        val
    end

    gradCfg = ForwardDiff.GradientConfig(loss, p0, get_chunk(p0))
    grad!(g, p) = ForwardDiff.gradient!(g, loss, p, gradCfg) 
    
    try
        # TODO automatically use LM / LsqFit when we have a quadratic loss function
        loss0 = loss(p0)
        # minimize loss function
        res = Optim.optimize(loss, grad!, p0, LBFGS(), Optim.Options(iterations=10)) # TODO tunable iterations
        # update parameters in the solution if an improvement is found
        fevals += Optim.f_calls(res)
        if isnan(loss0) || isinf(loss0) || Optim.minimum(res) < loss0
            copyto!(p0, Optim.minimizer(res))
            updateparam!(prog, p0)
        end
    catch ex
        (ex isa InterruptException) && rethrow()
        # warn about exceptions from Optim
        @warn ex
    end
    
    fevals
end

# must not make changes to gp (thread-safety)
# potentially changes prog, definitely changes buffers
function fitness_function!(prog, buffers, gp::Algorithm{T}; optimize=false) where {T}
    fevals = 1

    param = extractparam(T, prog)
    if optimize && !isempty(param) 
        fevals += optimize!(prog, param, buffers, gp)
    end
    
    loss = gp.loss_func(param, prog, gp, buffers)
    
    # fitness is negative loss
    (isnan(loss) || isinf(loss)) && return -floatmax(loss),fevals
    -loss, fevals
end

function tostring(prog)
    buf = IOBuffer()
    print_indiv(buf, prog)
    String(take!(buf))
end

function print_indiv(io::IO, prog, pos=1)
    primitive = prog[pos].opcode
    if primitive < FSET_START
        print(io, "X", primitive)
        return pos
    elseif primitive == PARAM
        print(io, prog[pos].val)
        return pos
    elseif ARITY[primitive] == 1
        if primitive == EXP
            print(io, "exp(")
            endpos = print_indiv(io, prog, pos + 1)
            print(io, ")")
        elseif primitive == LOGABS
            print(io, "log(abs(")
            endpos = print_indiv(io, prog, pos + 1)
            print(io, ")")
        end
        return endpos
    elseif ARITY[primitive] == 2
        if primitive in (ADD, SUB, MUL)
            print(io, "(")
            nextpos = print_indiv(io, prog, pos + 1)
            if primitive == ADD
                print(io, " + ")
            elseif primitive == SUB
                print(io, " - ")
            elseif primitive == MUL
                print(io, " * ")
            end
            endpos = print_indiv(io, prog, nextpos + 1)
            print(io, ")")
        elseif primitive == DIV
            print(io, "pdiv(")
            nextpos = print_indiv(io, prog, pos + 1)
            print(io, ", ")
            endpos = print_indiv(io, prog, nextpos + 1)
            print(io, ")")
        elseif primitive == POWABS
            print(io, "(abs(")
            nextpos = print_indiv(io, prog, pos + 1)
            print(io, ") ^ ")
            endpos = print_indiv(io, prog, nextpos + 1)
            print(io, ")")
        end

        return endpos
    end
end

function tournament(gp::Algorithm{T}) where {T}
    group = rand(eachindex(gp.pop), gp.tournamentsize)
    bestfitness,bestidx = findmax(gp.fitness[group])
    group[bestidx]
end

function crossover(gp, parent1, parent2)
    len1 = traverse(parent1, 1)
    len2 = traverse(parent2, 1)
    
    # this is the part we cut out of p1
    xo1start = rand(0:len1 - 1)
    xo1end = traverse(parent1, xo1start + 1)
    
    p1len = xo1start 
    p3len = len1 - xo1end
    
    # this is the part we use from p2
    xo2start = rand(0:len2 - 1)
    xo2end = traverse(parent2, xo2start + 1)
    p2len = xo2end - xo2start
    while p1len + p2len + p3len > gp.maxlen
        xo2start = rand(0:len2 - 1)
        xo2end = traverse(parent2, xo2start + 1)
        p2len = xo2end - xo2start
    end

    offspring = Vector{Instruction}(undef,  p1len + p2len + p3len)
    copyto!(offspring, 1,                 parent1, 1, p1len)
    copyto!(offspring, 1 + p1len,         parent2, xo2start + 1, p2len)
    copyto!(offspring, 1 + p1len + p2len, parent1, xo1end + 1, p3len)

    @assert length(offspring) <= gp.maxlen

    offspring
end

function mutate!(indiv, pmut, numvars)
    for i in eachindex(indiv)
        if rand() < pmut
            if indiv[i].opcode < FSET_START || indiv[i].opcode == PARAM
                if rand() < 0.5
                    # create parameter and change value slightly
                    indiv[i] = Instruction(PARAM, indiv[i].val + randn()) # + delta ~ N(0, 1), may want to force larger jumps here
                else
                    # create variable
                    indiv[i] = Instruction(rand(1:numvars), indiv[i].val) 
                end
            else
                newfunc = UInt8(rand(FSET_START:FSET_END)) # random operator or function
                while ARITY[newfunc] != ARITY[indiv[i].opcode]
                    newfunc = UInt8(rand(FSET_START:FSET_END)) # random operator or function
                end
                indiv[i] = Instruction(newfunc, indiv[i].val)
            end
        end
    end
    indiv
end

function update_stats!(gp::Algorithm{T}, gen) where {T}
    popsize = length(gp.pop)
    bestfitness,bestidx = findmax(gp.fitness)
    gp.fbestpop = bestfitness
    gp.favgpop = zero(T)
    node_count = 0
    for i in 1:popsize
        node_count += traverse(gp.pop[i], 1)
        gp.favgpop += gp.fitness[i]
    end
    gp.avg_len = node_count / popsize
    gp.favgpop /= popsize
    if gp.print_trace 
        @printf "Generation=%d Fitness evaluations=%d Avg Fitness=%f Best Fitness=%f Avg Size=%f\nBest Individual: " gen gp.fevals gp.favgpop gp.fbestpop gp.avg_len
        print_indiv(stdout, gp.pop[bestidx])
        println()
    end
end

function print_parms(gp)
    popsize = length(gp.pop)
    @printf("-- TINY GP (Julia version) --\n")
    @printf("SEED=%d\nMAX_LEN=%d\nPOPSIZE=%d\nDEPTH=%d\nCROSSOVER_PROB=%f\n\
            PMUT_PER_NODE=%f\nGENERATIONS=%d\n\
            TSIZE=%d\n----------------------------------\n",
            gp.seed, gp.maxlen, popsize, DEPTH, CROSSOVER_PROB,
            PMUT_PER_NODE, gp.generations, gp.tournamentsize)
end

function start_fitness_eval_workers(gp, workqueue, resultqueue)
    # fitness evaluation is done in thread-parallel workers with pre-allocated buffers
    for _ in 1:Threads.nthreads()
        Threads.@spawn begin
            try 
                buffers = InterpreterBuffers(eltype(gp.y), length(gp.y), varnumber(gp), gp.maxlen)
                for (i,indiv) in workqueue
                    f,fevals = fitness_function!(indiv, buffers, gp, optimize = true)
                    put!(resultqueue, (i, f, fevals))
                end
            catch ex
                @show ex
                for (exc, bt) in current_exceptions()
                    showerror(stdout, exc, bt)
                    println(stdout)
                end
            end
        end
    end
end

function evolve!(gp::Algorithm{T}; iter_callback=nothing) where {T}
    fitnessevalqueue = Channel{Tuple{Int64,Vector{Instruction}}}(Inf)
    resultqueue = Channel{Tuple{Int64,T,Int64}}(Inf)
    start_fitness_eval_workers(gp, fitnessevalqueue, resultqueue)

    # create random pop
    @timeit gp.to "initial population" begin
        Threads.@threads for i in eachindex(gp.pop) 
            gp.pop[i] = create_random_indiv(gp, DEPTH)
            put!(fitnessevalqueue, (i, gp.pop[i]))
        end
        begin
            # collect results
            waitingresults = length(gp.pop)
            while waitingresults > 0
                i, fit, fevals = take!(resultqueue)
                gp.fitness[i] = fit
                gp.fevals += fevals
                waitingresults -= 1
            end
        end
    end

    update_stats!(gp, 1)

    isnothing(iter_callback) || iter_callback()
    
    popsize = length(gp.pop)
    @timeit gp.to "generation loop" for gen in 2:gp.generations
        # generational replacement
        newpop = Vector{Vector{Instruction}}()
        sizehint!(newpop, popsize)
        newfitness = similar(gp.fitness)
        
        elitefitness,eliteidx = findmax(gp.fitness)
        push!(newpop, gp.pop[eliteidx])
        
        tasks = [Threads.@spawn begin 
            if rand() < CROSSOVER_PROB
                local parent1idx = tournament(gp)
                local parent2idx = tournament(gp)
                child = crossover(gp, gp.pop[parent1idx], gp.pop[parent2idx])
            else
                local parentidx = tournament(gp)
                child = copy(gp.pop[parentidx])
                mutate!(child, PMUT_PER_NODE, varnumber(gp))
            end
            child
        end for _ in 1:popsize-1]
        @timeit gp.to "selection & xover/mut" append!(newpop, fetch.(tasks))

        @assert length(newpop) == length(gp.pop)
        
        # also evaluate the elite again (for dynamic fitness function or parameter optimization)
        for i in eachindex(newfitness)
            put!(fitnessevalqueue, (i, newpop[i]))
        end
        # collect results
        waitingresults = length(newfitness)
        while waitingresults > 0
            i, fit, fevals = take!(resultqueue)
            newfitness[i] = fit
            gp.fevals += fevals
            waitingresults -= 1
        end
        
        copyto!(gp.pop, newpop)
        copyto!(gp.fitness, newfitness)
        update_stats!(gp, gen)
        
        isnothing(iter_callback) || iter_callback()
    end
    
    close(fitnessevalqueue) # signal for workers to stop
end


# only for testing
#gp = Algorithm{Float64}("problem.csv", "y", seed=3141, generations=10, popsize=1000, maxlen=25)
#@time evolve!(gp)
#print_timer(gp.to)
#@assert (@show gp.fbestpop) ≈  -0.0038802605687494776

end # module
