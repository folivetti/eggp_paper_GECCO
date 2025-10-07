module TinyGP

# TODO 
# - parameters in the code instead of ERC
# - univariate functions
# - AutoDiff
# - read from CSV (and automatically determine num vars and num obs)
# - postfix instead of prefix
# - batched evaluation
# - parallel evaluation
# - likelihoods
# - dl


using Random
using Printf

const ADD::UInt8 = 110
const SUB::UInt8 = 111
const MUL::UInt8 = 112
const DIV::UInt8 = 113
const EXP::UInt8 = 114
const FSET_START = ADD
const FSET_END = DIV

const ARITY = Dict(ADD => 2,
    SUB => 2,
    MUL => 2,
    DIV => 2,
    EXP => 1)

# Default parameter values
const MAX_LEN = 100
const POPSIZE = 10_000
const DEPTH = 5
const GENERATIONS = 100
const TSIZE = 2
const PMUT_PER_NODE = 0.05
const CROSSOVER_PROB = 0.9

const BUFFER = Vector{UInt8}(undef, MAX_LEN)

mutable struct Algorithm{T}
    const fitness::Vector{T}
    const pop::Vector{Vector{UInt8}}
    const rng::AbstractRNG
    const x::Vector{T}
    const minrandom::T
    const maxrandom::T
    const randomnumber::Int32
    const X::Matrix{T}
    const y::Vector{T}
    fbestpop::T
    favgpop::T
    avg_len::T
    const seed::Int64
    const generations::Int32
    const maxlen::Int32
    const tournamentsize::Int32
end

varnumber(gp) = size(gp.X, 2)
fitnesscases(gp) = size(gp.X, 1) # TODO should be removed

function Algorithm{T}(fname::AbstractString; seed=-1, generations=GENERATIONS, popsize=POPSIZE, maxlen=MAX_LEN, tournamentsize=TSIZE) where {T <: AbstractFloat}
    rng = seed >= 0 ? MersenneTwister(seed) : MersenneTwister()
    randomnumber, minrandom, maxrandom, X, y = setup_fitness(T, fname)
    
    varnumber = size(X, 2)
    varnumber + randomnumber < FSET_START || error("too many variables and constants")
    
    fitness = Vector{T}(undef, popsize)
    pop = Vector{Vector{UInt8}}(undef, popsize)
    x = [(maxrandom - minrandom) * rand(rng) + minrandom for _ in 1:FSET_START] # initialize ephemeral random constants
    gp = Algorithm{T}(fitness, pop, rng, x, minrandom, maxrandom, 
                randomnumber, X, y, 0.0, 0.0, 0.0, seed, generations, maxlen, tournamentsize)
    create_random_pop!(gp, popsize, DEPTH)
    return gp
end

function setup_fitness(::Type{T}, fname::AbstractString) where {T <: AbstractFloat}
    open(fname, "r") do io
        eof(io) && error("empty data file")
        header = split(strip(readline(io)))
        length(header) == 5 || error("expected five header values")
        varnumber = parse(Int, header[1])
        randomnumber = parse(Int, header[2])
        minrandom = parse(T, header[3])
        maxrandom = parse(T, header[4])
        fitnesscases = parse(Int, header[5])
        X = Matrix{T}(undef, fitnesscases, varnumber)
        y = Vector{T}(undef, fitnesscases)
        for i in 1:fitnesscases
            eof(io) && error("unexpected end of data at case $i")
            tokens = split(strip(readline(io)))
            length(tokens) >= varnumber + 1 || error("not enough values on line $i")
            for j in 1:(varnumber)
                X[i, j] = parse(Float64, tokens[j])
            end
            y[i] = parse(Float64, tokens[varnumber+1])
        end
        return randomnumber, minrandom, maxrandom, X, y
    end
end

# returns end of subexpression starting at pos
function traverse(buffer, pos)
    primitive = buffer[pos]
    if primitive < FSET_START
        return pos
    elseif ARITY[primitive] == 1
        traverse(buffer, pos + 1)
    elseif ARITY[primitive] == 2
        nextpos = traverse(buffer, pos + 1)
        return traverse(buffer, nextpos + 1)
    end
end

function grow!(gp, buffer, pos, maxlen, depth)
    pos >= maxlen && return -1
    prim = pos == 1 ? 1 : rand(gp.rng, 0:1)  # terminal or function but force terminal on first position
    if prim == 0 || depth == 0
        # random terminal
        code = rand(gp.rng, 1:(varnumber(gp) + gp.randomnumber))
        buffer[pos] = UInt8(code)
        return pos
    else
        # random function 
        func = UInt8(rand(gp.rng, FSET_START:FSET_END))
        buffer[pos] = func
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
    
    copyto!(Vector{UInt8}(undef, len), 1, BUFFER, 1, len)
end

function create_random_pop!(gp, popsize, depth)
    for i in 1:popsize
        gp.pop[i] = create_random_indiv!(gp, depth)
        gp.fitness[i] = fitness_function(gp, gp.pop[i])
    end
    
    gp.pop
end

function run_program(gp, prog)
    pc = 0
    
    function eval_node(gp)
        pc += 1
        primitive = prog[pc]
        if primitive < FSET_START
            return gp.x[primitive]
        else
            if primitive == ADD
                return eval_node(gp) + eval_node(gp)
            elseif primitive == SUB
                return eval_node(gp) - eval_node(gp)
            elseif primitive == MUL
                return eval_node(gp) * eval_node(gp)
            elseif primitive == DIV
                num = eval_node(gp)
                den = eval_node(gp)
                den ≈ 0.0 && return 0.0
                return num / den
            elseif primitive == EXP
                return exp(eval_node(gp))
            else
                error("unknown operator $primitive")
            end
        end
    end
    
    try 
        eval_node(gp)
    catch ex
        @show prog
        print_indiv(gp, prog)
        rethrow()
    end
end



function fitness_function(gp, prog)
    fit = 0.0
    for i in axes(gp.X, 1)
        for j in 1:varnumber(gp)
            gp.x[j] = gp.X[i, j]
        end
        result = run_program(gp, prog)
        fit += abs(result - gp.y[i])
    end
    -fit
end

function print_indiv(gp, buffer, pos=1)
    primitive = buffer[pos]
    if primitive < FSET_START
        if primitive <= varnumber(gp)
            print("X", primitive, " ")
        else
            print(gp.x[primitive])
        end
        return pos
    elseif ARITY[primitive] == 1
        if primitive == EXP
            print("exp(")
            endpos = print_indiv(gp, buffer, pos + 1)
            print(")")
        end
        return endpos
    elseif ARITY[primitive] == 2
        print("(")
        nextpos = print_indiv(gp, buffer, pos + 1)
        if primitive == ADD
            print(" + ")
        elseif primitive == SUB
            print(" - ")
        elseif primitive == MUL
            print(" * ")
        elseif primitive == DIV
            print(" / ")
        end
        endpos = print_indiv(gp, buffer, nextpos + 1)
        print(")")
        return endpos
    end
end

function tournament!(gp)
    popsize=length(gp.pop)
    bestidx = rand(gp.rng, 1:popsize)
    fbest = floatmin(eltype(gp.X))
    for _ in 1:gp.tournamentsize
        competitor = rand(gp.rng, 1:popsize)
        if gp.fitness[competitor] > fbest
            fbest = gp.fitness[competitor]
            bestidx = competitor
        end
    end
    bestidx
end

function negative_tournament!(gp)
    popsize=length(gp.pop)
    worstidx = rand(gp.rng, 1:popsize)
    fworst = floatmax(eltype(gp.X))
    for _ in 1:gp.tournamentsize
        competitor = rand(gp.rng, 1:popsize)
        if gp.fitness[competitor] < fworst
            fworst = gp.fitness[competitor]
            worstidx = competitor
        end
    end
    worstidx
end

function crossover(gp, parent1, parent2)
    len1 = traverse(parent1, 1)
    len2 = traverse(parent2, 1)
    xo1start = rand(gp.rng, 0:len1 - 1)
    xo1end = traverse(parent1, xo1start + 1)
    xo2start = rand(gp.rng, 0:len2 - 1)
    xo2end = traverse(parent2, xo2start + 1)
    p1len = xo1start
    p2len = xo2end - xo2start
    p3len = len1 - xo1end
    
    offspring = Vector{UInt8}(undef,  p1len + p2len + p3len)
    copyto!(offspring, 1,                 parent1, 1, p1len)
    copyto!(offspring, 1 + p1len,         parent2, xo2start + 1, p2len)
    copyto!(offspring, 1 + p1len + p2len, parent1, xo1end + 1, p3len)
    offspring
end

function mutate!(gp, parent, pmut)
    len = traverse(parent, 1)
    child = copy(parent)
    for i in 1:len
        if rand(gp.rng) < pmut
            if child[i] < FSET_START
                child[i] = UInt8(rand(gp.rng, 1:varnumber(gp)))
            else
                child[i] = UInt8(rand(gp.rng, FSET_START:FSET_END)) # random operator or function
            end
        end
    end
    child
end

function update_stats!(gp, gen)
    popsize = length(gp.pop)
    best = rand(gp.rng, 1:popsize)
    gp.fbestpop = gp.fitness[best]
    gp.favgpop = 0.0
    node_count = 0
    for i in 1:popsize
        node_count += traverse(gp.pop[i], 1)
        gp.favgpop += gp.fitness[i]
        if gp.fitness[i] > gp.fbestpop
            best = i
            gp.fbestpop = gp.fitness[i]
        end
    end
    gp.avg_len = node_count / popsize
    gp.favgpop /= popsize
    @printf "Generation=%d Avg Fitness=%f Best Fitness=%f Avg Size=%f\nBest Individual: " gen -gp.favgpop -gp.fbestpop gp.avg_len
    print_indiv(gp, gp.pop[best])
    println()
    flush(stdout)
end

function print_parms(gp)
    popsize = length(gp.pop)
    @printf("-- TINY GP (Julia version) --\n")
    @printf("SEED=%d\nMAX_LEN=%d\nPOPSIZE=%d\nDEPTH=%d\nCROSSOVER_PROB=%f\n\
            PMUT_PER_NODE=%f\nMIN_RANDOM=%f\nMAXRANDOM=%f\nGENERATIONS=%d\n\
            TSIZE=%d\n----------------------------------\n",
            gp.seed, gp.maxlen, popsize, DEPTH, CROSSOVER_PROB,
            PMUT_PER_NODE, gp.minrandom, gp.maxrandom, gp.generations, gp.tournamentsize)
end

function evolve!(gp)
    print_parms(gp)
    update_stats!(gp, 0)
    popsize = length(gp.pop)
    for gen in 1:gp.generations - 1
        if gp.fbestpop > -1e-5
            println("PROBLEM SOLVED")
            return
        end
        for _ in 1:popsize
            newind = if rand(gp.rng) < CROSSOVER_PROB
                parent1 = tournament!(gp)
                parent2 = tournament!(gp)
                crossover(gp, gp.pop[parent1], gp.pop[parent2])
            else
                parent = tournament!(gp)
                mutate!(gp, gp.pop[parent], PMUT_PER_NODE)
            end
            newfit = fitness_function(gp, newind)
            offspring = negative_tournament!(gp)
            gp.pop[offspring] = newind
            gp.fitness[offspring] = newfit
        end
        update_stats!(gp, gen)
    end
    println("PROBLEM *NOT* SOLVED")
end

function main(args)
    fname = "problem.dat"
    seed = -1
    if length(args) == 2
        seed = parse(Int, args[1])
        fname = args[2]
    elseif length(args) == 1
        fname = args[1]
    end
    gp = Algorithm{Float64}(fname, seed)
    evolve!(gp)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end

# only for testing
gp = Algorithm{Float64}("problem.dat", seed=3141, generations=2, popsize=1000)
evolve!(gp)
@assert (@show gp.favgpop) ≈ -780.3112327462827
@assert (@show gp.fbestpop) ≈ -30.64128742851832

end # module
