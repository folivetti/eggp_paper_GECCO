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
        "--batchsize", "-b"
            help = "Batch size"
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
        println("Usage: NeoGP.jl trainingdata.csv [--generations N] [--batchsize N] [--tournamentsize N] [--maxlen N] [--objective OBJ] [--testdataset FILE]")
        return
    end

    trainingfilename = parsed["training"]
    generations = parsed["generations"]
    batchsize = parsed["batchsize"]
    tsize = parsed["tournamentsize"]
    maxlen = parsed["maxlen"]
    nthreads = parsed["threads"]
    likelihoodstr = parsed["likelihood"]
    objective = parsed["objective"]

    data, varnames = load_RAR_data(Float32, trainingfilename)
    functionset = Set([NeoGP.ADD, NeoGP.SUB, NeoGP.MUL, NeoGP.DIV, NeoGP.EXP, NeoGP.LOGABS, NeoGP.SQRTABS, NeoGP.POWABS])
    if likelihoodstr == "unif"
        likelihood = RARLikelihood(data, varnames)
        NeoGP.print_lossfunction(stdout,likelihood); println()
        indiv_type = RARIndividual{RARLikelihood{Float32}}
    elseif likelihoodstr == "mnr"
        likelihood = RARMNRLikelihood(data, varnames)
        NeoGP.print_lossfunction(stdout,likelihood); println()
        indiv_type = RARIndividual{RARMNRLikelihood{Float32}}
    else
        error("unknown likelihood type (allowed values are gaussian, laplace, cosmic_chronometers)")
    end

    if objective == "nll"
        loss_func = NeoGP.loss
    elseif objective == "dl"
        loss_func = NeoGP.description_length
    else
        error("unknown objective function value")
    end

    gp = NeoGP.Algorithm(likelihood,
        generations = generations, batchsize = batchsize, maxlen = maxlen, tournamentsize = tsize,
        loss_func = loss_func, threads = nthreads, 
        functionset = functionset,
        individual_type = indiv_type)
    
    
    println("gen,fevals,best_fitness,dl,nll,func_compl,param_compl,avg_len,avg_fitness,size,expression")
    gen = 0
    callback = () -> begin
        gen += 1
        bestfitness = gp.bestfitness
        bestindiv = gp.bestindividual
        best_expr_str = NeoGP.tostring(bestindiv)
        
        (nll, func_compl, param_compl) = NeoGP.description_length_terms(bestindiv)
        dl = nll + func_compl + param_compl
        
        println("$gen,$(gp.fevals),$(-bestfitness),$(dl),$(nll),$func_compl,$param_compl,$(gp.avglen),$(-gp.avgfitness),$(NeoGP.individual_length(bestindiv)),\"$(best_expr_str)\"")
        nothing
    end
    
    if nthreads != 1
        TimerOutputs.disable_timer!(NeoGP.global_timer)
    end
    stats = @timed NeoGP.evolve!(gp, iter_callback = callback)
    
    # produce the final map
    println()
    println()
    println("Final MAP:")
    for (key,val) in sort(gp.map.dict)
        indiv = val[1]
        (nll, func_compl, param_compl) = NeoGP.description_length_terms(indiv)
        dl = nll + func_compl + param_compl

        println("$gen,$(gp.fevals),$(key[1]),$(key[2]),$(-val[2]),$(dl),$(nll),$(func_compl),$(param_compl),$(NeoGP.tostring(indiv))")
    end

    println("Time stats: $stats\n\n")
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



function check_rar()
    data, varnames = load_RAR_data(Float32, "datasets/RAR.csv")
    likelihood = RARLikelihood(data, varnames)
    # p0 * (abs(t1 + x)^t2 + x)
    code = NeoGP.Instruction[
        NeoGP.Instruction(NeoGP.MUL),   # p1 * (abs(p2 + x)^p3 + x)
        NeoGP.Instruction(NeoGP.PARAM, 0.84, 1), # p1
        NeoGP.Instruction(NeoGP.ADD),   # abs(p2 + x)^p3 + x
        NeoGP.Instruction(NeoGP.POWABS),# abs(p2 + x)^p3
        NeoGP.Instruction(NeoGP.ADD),   # p2 + x
        NeoGP.Instruction(NeoGP.PARAM, -0.02, 1), # p2
        NeoGP.Instruction(UInt(1)),     # x
        NeoGP.Instruction(NeoGP.PARAM, 0.38, 1), # p3
        NeoGP.Instruction(UInt(1))      # x
    ]
    
    indiv = NeoGP.Individual(code, likelihood)
    rarindiv = RARIndividual(indiv)
    buffers = NeoGP.InterpreterBuffers(Float32, NeoGP.numobs(likelihood), NeoGP.numvar(likelihood), length(code))
    @show NeoGP.optimize!(rarindiv, buffers)
    @show NeoGP.extractparam(Float32, rarindiv)
    @show NeoGP.description_length_terms(rarindiv)
end



if abspath(PROGRAM_FILE) == @__FILE__
    # check_rar()
    main(ARGS)
end
