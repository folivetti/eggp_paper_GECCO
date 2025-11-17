using ArgParse
using TimerOutputs
using DelimitedFiles
using NeoGP

include("CCIndividual.jl")

function main(argv)
    s = ArgParseSettings()
    @add_arg_table s begin
        "training"
            help = "Training data CSV file (positional)"
        "target"
            help = "Target variable name (positional)"
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
        "--objective", "-o"
            help = "Objective"
            default = "mse"
        "--sigma" # TODO support different likelihoods
            help = "Sigma value for Gaussian likelihood (only used if applicable, e.g., nll or dl objective). Can be a double value or a variable from the datasets"
        "--likelihood" # TODO support different likelihoods
            help = "Likelihood type (gaussian, laplace)"
            default = "gaussian"
        "--threads"
            help = "Maximum number of parallel threads"
            arg_type = Int
            default = -1
        "--test"
            help = "Test dataset file in CSV format (defaults to training file)"
            default = ""
    end
    
    parsed = parse_args(argv, s; as_symbols=false)
    if !haskey(parsed, "training") || !haskey(parsed, "target")
        println("Usage: NeoGP.jl trainingdata.csv targetvariable [--generations N] [--popsize N] [--tournamentsize N] [--maxlen N] [--objective OBJ] [--testdataset FILE]")
        return
    end

    trainingfilename = parsed["training"]
    targetname = parsed["target"]
    generations = parsed["generations"]
    popsize = parsed["popsize"]
    tsize = parsed["tournamentsize"]
    maxlen = parsed["maxlen"]
    objective = parsed["objective"]
    sigmastr = parsed["sigma"]
    nthreads = parsed["threads"]
    likelihoodstr = parsed["likelihood"]
    testdataset = parsed["test"] == "" ? trainingfilename : parsed["test"]


    if !isnothing(sigmastr)
        sigma_val = tryparse(Float32, sigmastr)
        if isnothing(sigma_val)
            X, y, sigma = load_dataset(Float32, trainingfilename, targetname, sigmastr)
            X_test, y_test, sigma_test = load_dataset(Float32, testdataset, targetname, sigmastr)

            nll_offset_train = 0.5 * sum(log.((2.0 * π) .* sigma.^2))
            nll_offset_test = 0.5 * sum(log.((2.0 * π) .* sigma_test.^2))
        else
            sigma = sigma_test = sigma_val
            X, y = load_dataset(Float32, trainingfilename, targetname)
            X_test, y_test = load_dataset(Float32, testdataset, targetname)

            nll_offset_train = length(y) / 2 * log(2.0 * π .* sigma^2)
            nll_offset_test =  length(y_test) / 2 * log(2.0 * π .* sigma_test^2)
        end
    else
        sigma = sigma_test = nothing
        X, y = load_dataset(Float32, trainingfilename, targetname)
        X_test, y_test = load_dataset(Float32, testdataset, targetname)
        nll_offset_train = 0.0
        nll_offset_test = 0.0
    end
    
    if likelihoodstr == "gaussian"
        likelihood_type = NeoGP.GaussianLikelihood
        indiv_type = NeoGP.Individual{NeoGP.GaussianLikelihood{Float32}}
        functionset = Set([NeoGP.ADD, NeoGP.SUB, NeoGP.MUL, NeoGP.DIV, NeoGP.SIN, NeoGP.EXP, NeoGP.LOGABS, NeoGP.SQRTABS, NeoGP.POWABS])
    elseif likelihoodstr == "laplace"
        likelihood_type = NeoGP.LaplaceLikelihood
        indiv_type = NeoGP.Individual{NeoGP.LaplaceLikelihood{Float32}}
        functionset = Set([NeoGP.ADD, NeoGP.SUB, NeoGP.MUL, NeoGP.DIV, NeoGP.SIN, NeoGP.EXP, NeoGP.LOGABS, NeoGP.SQRTABS, NeoGP.POWABS])
    elseif likelihoodstr == "cosmic_chronometers"
        likelihood_type = NeoGP.GaussianLikelihood
        indiv_type = CCIndividual{NeoGP.GaussianLikelihood{Float32}}
        # x = z + 1
        X .= X .+ 1.0
        X_test .= X_test .+ 1.0
        functionset = Set([NeoGP.ADD, NeoGP.SUB, NeoGP.MUL, NeoGP.DIV, NeoGP.INV, NeoGP.POWABS])
    else
        error("unknown likelihood type (allowed values are gaussian, laplace, cosmic_chronometers)")
    end

    if objective == "mse"
        if !isnothing(sigma)
            @warn "sigma argument is ignored when using mse objective"
        end
        @assert likelihood_type == NeoGP.GaussianLikelihood "MSE objective is only supported with Gaussian likelihood"
        likelihood = likelihood_type(X, y)
        likelihood_test = likelihood_type(X_test, y_test)
        loss_func = NeoGP.loss
    elseif objective == "r2"
        if !isnothing(sigma)
            @warn "sigma argument is ignored when using mse objective"
        end
        @assert likelihood_type == NeoGP.GaussianLikelihood "R2 objective is only supported with Gaussian likelihood"
        likelihood = likelihood_type(X, y)
        likelihood_test = likelihood_type(X_test, y_test)
        loss_func = NeoGP.loss
    elseif objective == "nll"
        # TODO allow specification of different likelihoods
        likelihood = likelihood_type(X, y, sigma) # optimize sigma
        likelihood_test = likelihood_type(X_test, y_test, sigma)
        loss_func = NeoGP.loss
    elseif objective == "dl"
        # TODO allow specification of different likelihoods
        likelihood = likelihood_type(X, y, sigma) # optimize sigma
        likelihood_test = likelihood_type(X_test, y_test, sigma)
        loss_func = NeoGP.description_length
    elseif objective == "nll-dl"
        # TODO allow specification of different likelihoods
        # likelihood = likelihood_type(X, y, sigma) # optimize sigma
        # likelihood_test = likelihood_type(X_test, y_test, sigma)
        # loss_func = (params...) -> gp.gen < 0.35 * gp.maxgenerations ? NeoGP.negloglik(params...) : NeoGP.description_length(params...)
    else
        error("unknown objective function value (allowed values are mse, r2, nll, dl)")
    end

    gp = NeoGP.Algorithm(likelihood,
        generations = generations, popsize = popsize, maxlen = maxlen, tournamentsize = tsize,
        loss_func = loss_func, threads = nthreads, 
        functionset = functionset,
        individual_type = indiv_type)

    println("gen,fevals,best_fitness,nll,dl,func_compl,param_compl,MSE_train,MSE_test,R2_train,R2_test,avg_len,avg_fitness,size,expression")
    gen = 0
    callback = () -> begin
        gen += 1
        bestfitness,bestidx = findmax(gp.fitness)
        bestindiv = gp.pop[bestidx]
        best_expr_str = NeoGP.tostring(bestindiv)
        ypred_train = NeoGP.predict(bestindiv, likelihood.X) 
        ypred_test  = NeoGP.predict(bestindiv, X_test)
        mse_train   = NeoGP.mean_squared_error(likelihood.y, ypred_train)
        mse_test    = NeoGP.mean_squared_error(y_test, ypred_test)
        r2_train    = NeoGP.r2_score(likelihood.y, ypred_train)
        r2_test     = NeoGP.r2_score(y_test, ypred_test)
        # likparam    = NeoGP.extractparam(NeoGP.getlossfunction(bestindiv))
        #nll_train   = NeoGP.negloglik(likelihood, ypred_train, likparam)
        #nll_test    = NeoGP.negloglik(likelihood_test, ypred_test, likparam)
        
        # this is just to produce the terms of the description_length (TODO: simplify)
        (nll, func_compl, param_compl) = NeoGP.description_length_terms(NeoGP.copy_indiv(bestindiv))
        dl = nll + func_compl + param_compl
        
        println("$gen,$(gp.fevals),$(-bestfitness),$(nll-nll_offset_train),$(dl-nll_offset_train),$func_compl,$param_compl,$mse_train,$mse_test,$r2_train,$r2_test,,$(gp.avg_len),$(-gp.favgpop),$(NeoGP.individual_length(bestindiv)),\"$(best_expr_str)\"")
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


# all columns except for the target are allowed input
function load_dataset(::Type{T}, filename::AbstractString, targetname) where {T <: AbstractFloat}
    data,varnames = readdlm(filename, ',', T, header=true)
    
    targetidx = findfirst((==)(targetname), varnames[1, :])
    isnothing(targetidx) && error("Could not find variable $targetname in $filename (with varnames: $varnames)")
    
    X = data[:, setdiff(1:end, targetidx)]
    y = data[:, targetidx]
    X, y
end

# all columns except for the target and target error are allowed input
function load_dataset(::Type{T}, filename::AbstractString, targetname, targeterrorname) where {T <: AbstractFloat}
    data,varnames = readdlm(filename, ',', T, header=true)
    
    targetidx = findfirst((==)(targetname), varnames[1, :])
    isnothing(targetidx) && error("Could not find variable $targetname in $filename (with varnames: $varnames)")

    targeterroridx = findfirst((==)(targeterrorname), varnames[1, :])
    isnothing(targeterroridx) && error("Could not find variable $targeterrorname in $filename (with varnames: $varnames)")
    
    X = data[:, setdiff(1:end, [targetidx, targeterroridx])]
    y = data[:, targetidx]
    y_err = data[:, targeterroridx]
    X, y, y_err
end


if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
