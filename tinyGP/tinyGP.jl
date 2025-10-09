module TinyGP



# TODO 
# - postfix instead of prefix
# - batched evaluation and preallocation of buffers 
# - likelihoods
# - dl
# - better command line argument parsing


using TimerOutputs
using Random
using Printf
using Optim # gradient-based optimization of parameters
using PreallocationTools 
using DelimitedFiles

# TODO check this
using ForwardDiff, Preferences
set_preferences!(ForwardDiff, "nansafe_mode" => true) 

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
const FSET_START = ADD
const FSET_END = POWABS

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

const BUFFER = Vector{Instruction}(undef, MAX_LEN)

mutable struct Algorithm{T}
    const fitness::Vector{T}
    const pop::Vector{Vector{Instruction}}
    const rng::AbstractRNG
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
end

varnumber(gp) = size(gp.X, 2)

function Algorithm{T}(fname::AbstractString, targetname; 
    seed=-1, generations=GENERATIONS, popsize=POPSIZE, 
    maxlen=MAX_LEN, tournamentsize=TSIZE,print_trace=false) where {T <: AbstractFloat}
    rng = seed >= 0 ? MersenneTwister(seed) : MersenneTwister()
    
    X, y = load_dataset(T, fname, targetname)
    
    varnumber = size(X, 2)
    varnumber < FSET_START || error("too many variables")
    
    fitness = Vector{T}(undef, popsize)
    pop = Vector{Vector{Instruction}}(undef, popsize)
    
    gp = Algorithm{T}(fitness, pop, rng, X, y, 0.0, 0.0, 0.0, 0, seed, generations, maxlen, tournamentsize, TimerOutput(), print_trace)
    
    print_parms(gp)
   
    create_random_pop!(gp, popsize, DEPTH)
    return gp
end

# all columns except for the target are allowed input
function load_dataset(::Type{T}, filename::AbstractString, targetname) where {T <: AbstractFloat}
    data,varnames = readdlm(filename, ',', header=true)
    
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

function grow!(gp::Algorithm{T}, buffer, pos, maxlen, depth) where {T}
    pos > maxlen && return -1
    prim = pos == 1 ? 1 : rand(gp.rng, 0:1)  # terminal or function but force terminal on first position
    if prim == 0 || depth == 0
        # random value initial value ~ N(0,1) for the terminal node (ineffective for variables)
        randval = randn(gp.rng, T)
        if rand(gp.rng) < 0.5
            varCode = rand(gp.rng, 1:varnumber(gp))
            buffer[pos] = Instruction(UInt8(varCode), randval)
            return pos
        else
            buffer[pos] = Instruction(UInt8(PARAM), randval)
            return pos
        end
    else
        func = UInt8(rand(gp.rng, FSET_START:FSET_END))
        buffer[pos] = Instruction(func)
        child = grow!(gp, buffer, pos + 1, maxlen, depth - 1)
        (child < 0 || ARITY[func] == 1) && return child # unary functions
        
        # binary functions
        return grow!(gp, buffer, child + 1, maxlen, depth - 1)
    end
end

function create_random_indiv!(gp, depth)
    len = grow!(gp, BUFFER, 1, gp.maxlen, depth)
    # retry if the random individual was too long
    while len < 0
        len = grow!(gp, BUFFER, 1, gp.maxlen, depth)
    end
    
    copyto!(Vector{Instruction}(undef, len), 1, BUFFER, 1, len)
end

function create_random_pop!(gp, popsize, depth)
    for i in 1:popsize
        gp.pop[i] = create_random_indiv!(gp, depth)
        # print_indiv(gp.pop[i]); println() # debugging
    end
    Threads.@threads for i in eachindex(gp.fitness) 
        gp.fitness[i] = fitness_function(gp, gp.pop[i], optimize=true)
    end
    
    gp.pop
end

function extractparam(prog)
    param = Float64[]

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

function run_program(prog, x::AbstractArray{T}, param::AbstractVector{TE})::TE  where {T <: AbstractFloat, TE <: Real}
    pc = 0
    paramidx = 0
    function eval_node()
        pc += 1
        primitive = prog[pc].opcode
        if primitive < FSET_START
            return x[primitive]
        elseif primitive == PARAM
            paramidx += 1
            return param[paramidx]
        elseif primitive == ADD
            return eval_node() + eval_node()
        elseif primitive == SUB
            return eval_node() - eval_node()
        elseif primitive == MUL
            return eval_node() * eval_node()
        elseif primitive == DIV
            num = eval_node()
            den = eval_node()
            iszero(den) && return zero(T)
            return num / den
        elseif primitive == EXP
            return exp(eval_node())
        elseif primitive == LOGABS
            return log(abs(eval_node()))
        elseif primitive == POWABS
            return abs(eval_node()) ^ eval_node()
        else
            error("unknown operator $primitive")
        end
    end
    
    eval_node()
end


function mean_squared_error(y::AbstractArray{T}, ypred::AbstractArray{TE}) where {T <: Real, TE <: Real}
    @assert length(y) == length(ypred)
    sumsq = zero(TE)
    for i in eachindex(y)
        sumsq += (y[i] - ypred[i])^2
    end
    sumsq / length(y)
end


#=
# demo task distribution for allocating one buffer for each thread
# to implement later

ntasks = Thraeds.nthraeds()  # use a larger values if `do_stuff!` contains I/O
@sync begin
    workqueue = Channel{Tuple{Int,Float64}}(Inf)

    # Do this after `@spawn`s if computing work itself is CPU-intensive
    for (i, x) in enumerate(xs)
        put!(workqueue, (i, x))
    end
    close(workqueue)  # signal the end of work

    for _ in 1:ntasks
        @spawn begin
            local matrix = zeros(2, 2)  # allocate the buffer, and don't share
            for (i, x) in workqueue
                out[i] = do_stuff!(matrix, x)
            end
        end
    end
end
=#


# predict with parameters stored in solution
predict(prog, X) = predict!(DiffCache(eltype(X)), prog, X)
predict!(ypred, prog, X) = predict!(ypred, prog, X, extractparam(prog))

# predict with parameter values explicitly given
predict(prog, X, p) = predict!(DiffCache(eltype(X)), prog, X, p)
function predict!(ypred, prog, X, p)
    for i in axes(X, 1)
        xi = @view X[i, :]
        ypred[i] = run_program(prog, xi, p)
    end
    ypred
end

# must be thread-safe
function fitness_function(gp, prog; optimize=false)
    ypred_buffer = DiffCache(similar(gp.y)) # TODO preallocate once per thread

    function loss(p)
        gp.fevals += 1
        ypred = get_tmp(ypred_buffer, p)
        predict!(ypred, prog, gp.X, p)
        mse = mean_squared_error(gp.y, ypred)
        (isnan(mse) || mse > 1e100) && return floatmax(eltype(p))
        
        mse
    end

    param = extractparam(prog)
    fit = loss(param)
    if length(param) > 0 && optimize
        try
            res = Optim.optimize(loss, param, LBFGS(), autodiff = :forward, Optim.Options(iterations=10)) # TODO tunable iterations
            # println(summary(res))
            # update parameters in the solution if an improvement is found
            if isnan(fit) || isinf(fit) || Optim.minimum(res) < fit
                param = Optim.minimizer(res)
                updateparam!(prog, param)
                fit = Optim.minimum(res)
            end
        catch ex
            # ignore exceptions from Optim
            @warn ex
        end
    end
    (isnan(fit) || isinf(fit)) && return -floatmax(T)
    -fit
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
    popsize = length(gp.pop)
    bestidx = rand(gp.rng, 1:popsize)
    fbest = floatmin(T)
    for _ in 1:gp.tournamentsize
        competitor = rand(gp.rng, 1:popsize)
        if gp.fitness[competitor] > fbest
            fbest = gp.fitness[competitor]
            bestidx = competitor
        end
    end
    bestidx
end

function crossover(gp, parent1, parent2)
    len1 = traverse(parent1, 1)
    len2 = traverse(parent2, 1)
    
    # this is the part we cut out of p1
    xo1start = rand(gp.rng, 0:len1 - 1)
    xo1end = traverse(parent1, xo1start + 1)
    
    p1len = xo1start 
    p3len = len1 - xo1end
    
    # this is the part we use from p2
    xo2start = rand(gp.rng, 0:len2 - 1)
    xo2end = traverse(parent2, xo2start + 1)
    p2len = xo2end - xo2start
    while p1len + p2len + p3len > gp.maxlen
        xo2start = rand(gp.rng, 0:len2 - 1)
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

function mutate!(indiv, pmut, numvars, rng)
    for i in eachindex(indiv)
        if rand(rng) < pmut
            if indiv[i].opcode < FSET_START
                # convert variable to param (values are copied but ineffective for variables)
                indiv[i] = Instruction(PARAM, indiv[i].val + randn(rng)) # + delta ~ N(0, 1), may want to force larger jumps here
            elseif indiv[i].opcode == PARAM
                # convert param to variable
                indiv[i] = Instruction(rand(rng, 1:numvars), indiv[i].val) 
            else
                newfunc = UInt8(rand(rng, FSET_START:FSET_END)) # random operator or function
                while ARITY[newfunc] != ARITY[indiv[i].opcode]
                    newfunc = UInt8(rand(rng, FSET_START:FSET_END)) # random operator or function
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

function evolve!(gp; iter_callback=nothing)
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
        
        for _ in 1:popsize-1
            newind = if rand(gp.rng) < CROSSOVER_PROB
                @timeit gp.to "tournament" parent1 = tournament(gp)
                @timeit gp.to "tournament" parent2 = tournament(gp)
                @timeit gp.to "xover" crossover(gp, gp.pop[parent1], gp.pop[parent2])
            else
                @timeit gp.to "tournament" parent = tournament(gp)
                @timeit gp.to "mutation" mutate!(gp.pop[parent], PMUT_PER_NODE, varnumber(gp), gp.rng)
            end
            push!(newpop, newind)
        end

        # also evaluate the elite again (for dynamic fitness function or parameter optimization)
        @timeit gp.to "fitness" Threads.@threads for i in eachindex(newpop)
            newfitness[i] = fitness_function(gp, newpop[i], optimize=true)
        end

        
        copyto!(gp.pop, newpop)
        copyto!(gp.fitness, newfitness)
        update_stats!(gp, gen)
        
        isnothing(iter_callback) || iter_callback()
    end
end

function main(args)
     if length(args) < 5 || length(args) > 6
        println("Usage: tinyGP.jl trainingdata.csv targetvariable generations popsize tournamentsize [ testdataset ]")
        return 
    end
    trainingfilename = args[1]
    targetname = args[2]
    generations = parse(Int, args[3])
    popsize = parse(Int, args[4])
    tsize = parse(Int, args[5])
    testdataset = length(args) == 6 ? args[6] : trainingfilename
    
    X_test, y_test = load_dataset(Float64, testdataset, targetname)
    
    gp = Algorithm{Float64}(trainingfilename, targetname, 
        generations=generations, popsize=popsize, maxlen=25, tournamentsize=tsize)

    ypred_test = similar(y_test)
    println("gen,fevals,mse_train,mse_test,avg_len,best_expr")
    gen = 0
    callback = () -> begin
        gen += 1
        bestfitness,bestidx = findmax(gp.fitness)
        buf = IOBuffer()
        print_indiv(buf, gp.pop[bestidx])
        best_expr_str = String(take!(buf))
        predict!(ypred_test, gp.pop[bestidx], X_test)
        println("$gen,$(gp.fevals),$(-bestfitness),$(mean_squared_error(y_test, ypred_test)),$(gp.avg_len),$(best_expr_str)")
        
    end
    evolve!(gp, iter_callback = callback)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end

# only for testing
#gp = Algorithm{Float64}("problem.csv", "y", seed=3141, generations=10, popsize=1000, maxlen=25)
#@time evolve!(gp)
#print_timer(gp.to)
#@assert (@show gp.fbestpop) ≈  -0.0038802605687494776

end # module
