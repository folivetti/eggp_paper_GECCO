using ArgParse
using TimerOutputs
using DelimitedFiles
using NeoGP

include("RAR.jl")

function main(argv)
    s = ArgParseSettings()
    @add_arg_table s begin
        "training"
            help = "RAR data CSV file (positional)"
        "--generations", "-g"
            help = "Number of generations"
            arg_type = Int
            default = 100
        "--popsize", "-p"
            help = "Population size"
            arg_type = Int
            default = 100
        "--tournamentsize", "-t"
            help = "Tournament size."
            arg_type = Int
            default = 2
        "--maxlen", "-m"
            help = "Maximum expression length"
            arg_type = Int
            default = 50
        "--likelihood" # TODO support different likelihoods
            help = "Likelihood type (unif)"
            default = "unif"
        "--objective", "-o"
            help = "Objective"
            default = "nll"
        "--threads"
            help = "Maximum number of parallel threads"
            arg_type = Int
            default = -1
    end
    
    parsed = parse_args(argv, s; as_symbols=false)
    if !haskey(parsed, "training")
        println("Usage: NeoGP.jl trainingdata.csv [--generations N] [--popsize N] [--tournamentsize N] [--maxlen N] [--objective OBJ] [--testdataset FILE]")
        return
    end

    trainingfilename = parsed["training"]
    generations = parsed["generations"]
    popsize = parsed["popsize"]
    tsize = parsed["tournamentsize"]
    maxlen = parsed["maxlen"]
    nthreads = parsed["threads"]
    likelihoodstr = parsed["likelihood"]
    objective = parsed["objective"]

    if likelihoodstr == "unif"
        data, varnames = load_RAR_data(Float32, trainingfilename)
        likelihood = RARLikelihood(data, varnames)
        indiv_type = RARIndividual
        # TODO
        functionset = Set([NeoGP.ADD, NeoGP.SUB, NeoGP.MUL, NeoGP.DIV, NeoGP.SIN, NeoGP.EXP, NeoGP.LOGABS, NeoGP.SQRTABS, NeoGP.POWABS])
    else
        error("unknown likelihood type (allowed values are gaussian, laplace, cosmic_chronometers)")
    end

    if objective == "nll"
        loss_func = NeoGP.negloglik
    elseif objective == "dl"
        loss_func = NeoGP.description_length
    elseif objective == "nll-dl"
        loss_func = (params...) -> gp.gen < 0.35 * gp.maxgenerations ? NeoGP.negloglik(params...) : NeoGP.description_length(params...)
    else
        error("unknown objective function value")
    end

    gp = NeoGP.Algorithm(likelihood,
        generations = generations, popsize = popsize, maxlen = maxlen, tournamentsize = tsize,
        loss_func = loss_func, threads = nthreads, 
        functionset = functionset,
        individual_type = indiv_type)

    println("gen,fevals,best_fitness,dl,func_compl,param_compl,nll_train,avg_len,avg_fitness,size,expression")
    gen = 0
    callback = () -> begin
        gen += 1
        bestfitness,bestidx = findmax(gp.fitness)
        bestindiv = gp.pop[bestidx]
        best_expr_str = NeoGP.tostring(bestindiv)
        ypred_train = NeoGP.predict(bestindiv, likelihood.X) 
        likparam    = NeoGP.extractparam(NeoGP.getlikelihood(bestindiv))
        nll_train   = NeoGP.negloglik(likelihood, ypred_train, likparam)
        
        # this is just to produce the terms of the description_length (TODO: simplify)
        (nll, func_compl, param_compl) = NeoGP.description_length_terms(NeoGP.copy(bestindiv))
        dl = nll + func_compl + param_compl
        
        println("$gen,$(gp.fevals),$(-bestfitness),$(dl-nll_offset_train),$func_compl,$param_compl,$(nll_train-nll_offset_train),$(gp.avg_len),$(-gp.favgpop),$(NeoGP.node_count(bestindiv))),\"$(best_expr_str)\"")
        nothing
    end
    
    TimerOutputs.disable_timer!(gp.to)
    if nthreads != 1
        TimerOutputs.disable_timer!(NeoGP.global_timer)
    end
    @time NeoGP.evolve!(gp, iter_callback = callback)
    
    nthreads == 1 && TimerOutputs.print_timer(NeoGP.global_timer)
    nothing
end

function load_RAR_data(::Type{T}, filename::AbstractString) where {T <: AbstractFloat}
    # as reported in https://arxiv.org/pdf/2301.04368.pdf Eq. 3
    # additional info from Harry Desmond:
    # e_loggbar = e_gbar / (gbar * np.log(10.))
    # e_loggobs = e_gobs / (gobs * np.log(10.))
    # sigma2_tot = e_loggobs**2 + (gobs1_diff*e_loggbar)**2
    # negloglike = 0.5 * np.sum((np.log10(gobs) - np.log10(gobs1))**2 ./ sigma2_tot + np.log(2.* np.pi * sigma2_tot))
  
    m,header = readdlm(filename, ',', T; header=true)
    header = header[1,:]
    gbar = m[:,findfirst((==)("gbar"), header)]
    gobs = m[:,findfirst((==)("gobs"), header)]
    log_gobs = log10.(gobs)
    log_gbar = log10.(gbar)
    e_log_gbar = m[:, findfirst((==)("e_gbar"), header)] ./ (gbar * T(log(10)))
    e_log_gobs = m[:, findfirst((==)("e_gobs"), header)] ./ (gobs * T(log(10)))

    varnames = ["gbar", "log_gbar", "e_log_gbar^2", "log_gobs", "e_log_gobs^2"]
    data = [gbar log_gbar  e_log_gbar.^2 log_gobs e_log_gobs.^2] # for MNR likelihood we require squared errors and calculate them once
    data, varnames
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
