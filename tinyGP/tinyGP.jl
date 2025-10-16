module TinyGP

# TODO 
# - symbols: neg, inv, aq, sin, cos, tanh, ...
# - Test speedup / accuracy with Float32
# - threads kwarg only sets the number of evaluation threads (other parts still use all threads)
# - automatically use LM / LsqFit when we have a quadratic loss function


include("likelihoods.jl")
include("lossfunctions.jl")

using TimerOutputs
using Random
using Printf
using Optim # gradient-based optimization of parameters
using PreallocationTools 

# https://juliadiff.org/ForwardDiff.jl/stable/user/advanced/
# In the future, we plan on allowing users and downstream library authors to dynamically enable NaN-safe mode via the AbstractConfig API.
# nansafe_mode option must be set for ForwardDiff before loading the package
using Preferences,UUIDs
# TODO: test effect
set_preferences!(UUID("f6369f11-7733-5829-9624-2563aa707210"), "nansafe_mode" => true) # ForwardDiff package UUID

using ForwardDiff

using LinearAlgebra # for svd in DL


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

struct Instruction 
    opcode::UInt8
    val::Float32
end

Instruction(opcode) = Instruction(opcode, 0.0f0)


# New Individual type to store both program and a likelihood object
struct Individual{T <: Likelihood}
    program::Vector{Instruction}
    likelihood::T
end

copy(indiv::Individual) = Individual(deepcopy(indiv.program), copy(indiv.likelihood))


mutable struct Algorithm{T,L <: Likelihood{T},F2}
    const likelihood::L # this is what is used for parameter optimization
    const loss_func::F2 # the function used to determine fitness (negative fitness), does not have to be a likelihood as it could be DL # TODO rename?
    const fitness::Vector{T}
    const pop::Vector{Individual{L}} 
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
    const nthreads::Int32
end


# this is a simple interface to for Gaussian likelihood where sigma_err is optimized (= least squares)
Algorithm(X::AbstractMatrix, y::AbstractVector; kwargs...) = Algorithm(GaussianLikelihood(X, y), kwargs...)
    
# Options for loss_func are: negloglik, description_length
function Algorithm(likelihood::LT;
    seed=-1, generations=GENERATIONS, popsize=POPSIZE, 
    maxlen=MAX_LEN, tournamentsize=TSIZE, print_trace=false, 
    loss_func::F2 = negLogLik,  # the interface for loss functions must be (::Likelihood, program::Vector{Instruction}, param::AbstractVector{T <: Real}, buffers::InterpreterBuffers)
    threads=0) where {T <: AbstractFloat, LT <: Likelihood{T}, F2}
    
    seed >= 0 && seed!(seed)
    threads <= 0 && (threads = Threads.nthreads())

    numvar(likelihood) < FSET_START || error("too many variables")
    
    fitness = Vector{T}(undef, popsize)
    pop = Vector{Individual{LT}}(undef, popsize)
    
    gp = Algorithm{T,LT,F2}(likelihood, loss_func, fitness, pop, 0.0, 0.0, 0.0, 0, seed, generations, maxlen, 
        tournamentsize, TimerOutput(), print_trace, 
        threads)
    
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
    buffer = Instruction[]; sizehint!(buffer, gp.maxlen)
    while isempty(buffer)
        grow!(buffer, gp.maxlen, depth, numvar(gp.likelihood))
    end

    @assert length(buffer) == traverse(buffer, 1)
    
    Individual(buffer, randomize_parameters!(copy(gp.likelihood)))
end

function extractparam(::Type{T}, indiv::Individual) where {T}
    T[extractparam(indiv.likelihood)..., extractparam(T, indiv.program)...] # TODO could reduce allocations here
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

function updateparam!(indiv::Individual{T}, param) where {T}
    updateparam!(indiv.likelihood, @view param[1:numparam(indiv.likelihood)])
    updateparam!(indiv.program, @view param[numparam(indiv.likelihood)+1:end])
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

function run_program(prog, x, param, stack::AbstractMatrix{T}) where {T <: Real}
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
predict(indiv::Individual, X) = predict(indiv.program, X)
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


# convenience function for description length of an individual when called from userspace
function description_length(indv::Individual)
    T = eltype(indv.likelihood.y)
    param = extractparam(T, indv)
    buffers = InterpreterBuffers(T, numobs(indv.likelihood), numvar(indv.likelihood), length(indv.program))
    description_length(indv.likelihood, indv.program, param, buffers)
end

function description_length(lik::Likelihood, prog, param, buffers)
    T = eltype(param)
    p_compl = param_compl(lik, param, prog, buffers) # this potentially updates the parameters
    p_compl == floatmax(T) && return p_compl

    f_compl = func_compl(prog, buffers.symfreq)
    negloglik(lik, prog, param, buffers) + T(f_compl) + p_compl
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

function param_compl(lik::Likelihood, param, prog, buffers)
    T = eltype(param)    

    length(param) == 0 && return zero(T)

    loss = (p) -> negloglik(lik, prog, p, buffers)
    
    # make sure we are at a local optimum

    # gradCfg = ForwardDiff.GradientConfig(loss, param, get_chunk(param))
    # grad! = (g,p) -> ForwardDiff.gradient!(g, loss, p, gradCfg)
    # try
    #     loss0 = loss(param)
    #     res = Optim.optimize(loss, grad!, param, LBFGS(), Optim.Options(f_abstol=1e-5)) # TODO tunable iterations
    #     # println(res)
    #     if Optim.converged(res) || loss0 < Optim.minimum(res)
    #         param .= Optim.minimizer(res)
    #         updateparam!(prog, param)
    #     else
    #         return floatmax(T)
    #     end
    # catch ex
    #     @warn ex
    #     return floatmax(T)
    # end
    
    hessianCfg = ForwardDiff.HessianConfig(loss, param, get_chunk(param))
    fim = ForwardDiff.hessian(loss, param, hessianCfg)::Matrix{T}

    (any(isnan, fim) || any(isinf, fim)) && return floatmax(T)

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
function optimize!(indiv, p0, buffers, gp)
    fevals = 0

    loss(p) = negloglik(indiv.likelihood, indiv.program, p, buffers)

    gradCfg = ForwardDiff.GradientConfig(loss, p0, get_chunk(p0))
    grad!(g, p) = ForwardDiff.gradient!(g, loss, p, gradCfg) 
    
    try
        loss0 = loss(p0)
        # minimize loss function
        # @show tostring(indiv) loss0 p0
        res = Optim.optimize(loss, grad!, p0, LBFGS(), Optim.Options(iterations=100)) # TODO tunable iterations
        # println(res)
        # update parameters in the solution if an improvement is found
        fevals += Optim.f_calls(res)
        if isnan(loss0) || isinf(loss0) || Optim.minimum(res) < loss0
            copyto!(p0, Optim.minimizer(res))
            updateparam!(indiv, p0)
        end
        # @show p0 tostring(indiv) 
    catch ex
        (ex isa InterruptException) && rethrow()
        # warn about exceptions from Optim
        @warn ex
        
        # debugging
        # for (exc, bt) in current_exceptions()
        #             showerror(stdout, exc, bt)
        #             println(stdout)
        # end
    end
    
    fevals
end

# must not make changes to gp (thread-safety)
# potentially changes individual (parameter values), definitely changes buffers
function fitness_function!(indiv::Individual, buffers, gp::Algorithm{T}; optimize=false) where {T}
    fevals = 1

    param = extractparam(T, indiv)
    if optimize && !isempty(param) 
        fevals += optimize!(indiv, param, buffers, gp)
    end
    
    loss = gp.loss_func(indiv.likelihood, indiv.program, param, buffers)
    if isnan(loss) || isinf(loss) loss = floatmax(T) end
    -loss, fevals
end


function tostring(indiv::Individual)
    buf = IOBuffer()
    print_indiv(buf, indiv)
    String(take!(buf))
end

function print_indiv(io::IO, indiv::Individual, pos=1)
    print_indiv(io, indiv.program, pos)
    print(io, " [likelihood params: $(extractparam(indiv.likelihood))]")
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

# Updated crossover function to handle Individual type
function crossover(gp, parent1::Individual, parent2::Individual)
    prog1, prog2 = parent1.program, parent2.program
    
    len1 = traverse(prog1, 1)
    len2 = traverse(prog2, 1)
    
    # this is the part we cut out of p1
    xo1start = rand(0:len1 - 1)
    xo1end = traverse(prog1, xo1start + 1)
    
    p1len = xo1start 
    p3len = len1 - xo1end
    
    # this is the part we use from p2
    xo2start = rand(0:len2 - 1)
    xo2end = traverse(prog2, xo2start + 1)
    p2len = xo2end - xo2start
    while p1len + p2len + p3len > gp.maxlen
        xo2start = rand(0:len2 - 1)
        xo2end = traverse(prog2, xo2start + 1)
        p2len = xo2end - xo2start
    end

    offspring_prog = Vector{Instruction}(undef,  p1len + p2len + p3len)
    copyto!(offspring_prog, 1,                 prog1, 1, p1len)
    copyto!(offspring_prog, 1 + p1len,         prog2, xo2start + 1, p2len)
    copyto!(offspring_prog, 1 + p1len + p2len, prog1, xo1end + 1, p3len)

    @assert length(offspring_prog) <= gp.maxlen

    # Copy likelihood parameters from parent1 (arbitrary choice)
    Individual(offspring_prog, copy(parent1.likelihood))
end

function mutate!(indiv::Individual, pmut, numvars)
    # mutate likelihood parameters with the same probability as all other nodes
    if rand() < PMUT_PER_NODE
        randomize_parameters!(indiv.likelihood)
    end

    mutate!(indiv.program, pmut, numvars)
    indiv
end

function mutate!(prog, pmut, numvars)
    for i in eachindex(prog)
        if rand() < pmut
            if prog[i].opcode < FSET_START || prog[i].opcode == PARAM
                if rand() < 0.5
                    # create parameter and change value slightly
                    prog[i] = Instruction(PARAM, prog[i].val + randn()) # + delta ~ N(0, 1), may want to force larger jumps here
                else
                    # create variable
                    prog[i] = Instruction(rand(1:numvars), prog[i].val) 
                end
            else
                newfunc = UInt8(rand(FSET_START:FSET_END)) # random operator or function
                while ARITY[newfunc] != ARITY[prog[i].opcode]
                    newfunc = UInt8(rand(FSET_START:FSET_END)) # random operator or function
                end
                prog[i] = Instruction(newfunc, prog[i].val)
            end
        end
    end
    prog
end

function update_stats!(gp::Algorithm{T}, gen) where {T}
    popsize = length(gp.pop)
    bestfitness,bestidx = findmax(gp.fitness)
    gp.fbestpop = bestfitness
    gp.favgpop = zero(T)
    node_count = 0
    for i in 1:popsize
        node_count += traverse(gp.pop[i].program, 1)
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

function start_fitness_eval_workers(gp::Algorithm{T}, workqueue, resultqueue) where {T}
    # fitness evaluation is done in thread-parallel workers with pre-allocated buffers
    for _ in 1:gp.nthreads
        Threads.@spawn begin
            try 
                buffers = InterpreterBuffers(T, numobs(gp.likelihood), numvar(gp.likelihood), gp.maxlen)
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
    fitnessevalqueue = Channel{Tuple{Int64,Individual}}(Inf)  # Updated type
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
        newpop = Individual{typeof(gp.likelihood)}[];
        sizehint!(newpop, popsize)
        newfitness = similar(gp.fitness)
        
        elitefitness,eliteidx = findmax(gp.fitness)
        push!(newpop, copy(gp.pop[eliteidx]))
        
        tasks = [Threads.@spawn begin 
            if rand() < CROSSOVER_PROB
                local parent1idx = tournament(gp)
                local parent2idx = tournament(gp)
                child = crossover(gp, gp.pop[parent1idx], gp.pop[parent2idx])
            else
                local parentidx = tournament(gp)
                child = copy(gp.pop[parentidx])
                mutate!(child, PMUT_PER_NODE, numvar(gp.likelihood))
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
