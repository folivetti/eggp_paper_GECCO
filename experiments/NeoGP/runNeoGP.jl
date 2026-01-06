using ArgParse
using TimerOutputs
using DelimitedFiles
using NeoGP
using LinearAlgebra

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
        "--batchsize", "-b"
            help = "Batch size for fitness evaluations"
            arg_type = Int
            default = 100
        "--popsize", "-p"
            help = "Population size for tournament selection. MAP-Elites uses a variable-size archive of solution candidates. 
            This parameter creates a virtual population of the given size by selecting randomly from the archive for tournament selection."
            arg_type = Int
            default = 1000
        "--tournamentsize", "-t"
            help = "Tournament size for selection"
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

        "--threads"
            help = "Maximum number of parallel threads"
            arg_type = Int
            default = -1
        "--test"
            help = "Test dataset file in CSV format (defaults to training file)"
            default = ""
        # TODO: different algorithms
    end
    
    parsed = parse_args(argv, s; as_symbols=false)
    if !haskey(parsed, "training") || !haskey(parsed, "target")
        println("Usage: NeoGP.jl trainingdata.csv targetvariable [--generations N] [--batchsize N] [--popsize N] [--tournamentsize N] [--maxlen N] [--objective OBJ] [--testdataset FILE]")
        return
    end

    trainingfilename = parsed["training"]
    targetname = parsed["target"]
    generations = parsed["generations"]
    batchsize = parsed["batchsize"]
    popsize = parsed["popsize"]
    tournamentsize = parsed["tournamentsize"]
    maxlen = parsed["maxlen"]
    objective = lowercase(parsed["objective"])
    sigmastr = parsed["sigma"]
    nthreads = parsed["threads"]
    testdataset = parsed["test"] == "" ? trainingfilename : parsed["test"]

    
    if !isnothing(sigmastr)
        sigma_val = tryparse(Float32, sigmastr)
        if isnothing(sigma_val)
            X, y, sigma = load_dataset(Float32, trainingfilename, targetname, sigmastr)
            X_test, y_test, sigma_test = load_dataset(Float32, testdataset, targetname, sigmastr)
        else
            sigma = sigma_test = sigma_val
            X, y = load_dataset(Float32, trainingfilename, targetname)
            X_test, y_test = load_dataset(Float32, testdataset, targetname)
        end
    else
        sigma = sigma_test = nothing
        X, y = load_dataset(Float32, trainingfilename, targetname)
        X_test, y_test = load_dataset(Float32, testdataset, targetname)
    end
    
    functionset = Set([NeoGP.ADD, NeoGP.SUB, NeoGP.MUL, NeoGP.DIV, NeoGP.SIN, NeoGP.EXP, NeoGP.LOGABS, NeoGP.SQRTABS, NeoGP.POWABS])

    if objective == "mse"
        if !isnothing(sigma)
            @warn "sigma argument is ignored when using mse objective"
        end
        likelihood = NeoGP.GaussianLikelihood(X, y) # no advantage to fix sigma here because it is calculated implicitly from residuals anyway
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test)
        loss_func = (NeoGP.negloglik, NeoGP.individual_length)
        model_selection_obj = NeoGP.mean_squared_error
    elseif objective == "r2"
        if !isnothing(sigma)
            @warn "sigma argument is ignored when using mse objective"
        end
        likelihood = NeoGP.GaussianLikelihood(X, y)  # no advantage to fix sigma here because it is calculated implicitly from residuals anyway
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test)
        loss_func = (NeoGP.negloglik, NeoGP.individual_length)
        model_selection_obj = (-) ∘ NeoGP.r2_score
    elseif objective == "nll"
        likelihood = NeoGP.GaussianLikelihood(X, y, sigma)
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test, sigma_test)
        loss_func = (NeoGP.negloglik, NeoGP.individual_length)
        model_selection_obj = NeoGP.negloglik
    elseif objective == "aic"
        likelihood = NeoGP.GaussianLikelihood(X, y, sigma)
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test, sigma_test)
        loss_func = (NeoGP.negloglik, NeoGP.individual_length)
        model_selection_obj = NeoGP.AIC
    elseif objective == "bic"
        likelihood = NeoGP.GaussianLikelihood(X, y, sigma)
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test, sigma_test)
        loss_func = (NeoGP.negloglik, NeoGP.individual_length)
        model_selection_obj = NeoGP.BIC
    elseif objective == "dl"
        likelihood = NeoGP.GaussianLikelihood(X, y, sigma)
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test, sigma_test)
        loss_func = (NeoGP.negloglik, NeoGP.description_length_complexity_penalty)
        model_selection_obj = NeoGP.description_length
    elseif objective == "fbf"
        likelihood = NeoGP.GaussianLikelihood(X, y, sigma)
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test, sigma_test)
        loss_func = (NeoGP.negloglik, NeoGP.fractional_bayes_factor_complexity_penalty)
        model_selection_obj = NeoGP.fractional_bayes_factor
    else
        error("unknown objective function value (allowed values are mse, r2, nll, aic, bic, fbf, dl)")
    end
    # gp = NeoGP.MAPElitesAlgorithm(likelihood, tournamentsize = tournamentsize, popsize=popsize, batchsize = batchsize, maxlen = maxlen,
    #     indiv_loss_func = loss_func, threads = nthreads, functionset = functionset)
    # gp = NeoGP.BasicAlgorithm(likelihood, tournamentsize = tournamentsize, popsize=popsize, maxlen = maxlen,
    #     indiv_loss_func = loss_func, threads = nthreads, functionset = functionset)
    gp = NeoGP.NSGA2(likelihood, tournamentsize = tournamentsize, popsize=popsize, maxlen = maxlen,
        indiv_loss_func = loss_func, threads = nthreads, functionset = functionset)
    gen = 0
    println("gen,fevals,|bestfront|,bestloss,obj,nll,dl,func_compl,param_compl,FBF,MSE_train,MSE_test,R2_train,R2_test,size,expression")

    buffers = NeoGP.InterpreterBuffers(Float32, size(X, 1), size(X, 2), maxlen)
    buffers_test = NeoGP.InterpreterBuffers(Float32, size(X_test, 1), size(X_test, 2), maxlen)
    callback = () -> begin
        gen += 1
        
        front = filter(tup -> NeoGP.individual_length(tup[1]) <= maxlen, NeoGP.best_individuals(gp))  # filter out individuals that are too long
        
        
        bestobj, bestidx = findmin(tup -> model_selection_obj(tup[1], buffers), front)  # find individual with best model selection objective
        bestindiv, bestloss = front[bestidx]
        
        param = NeoGP.extractparam(Float32, NeoGP.getprogram(bestindiv))
        best_expr_str = NeoGP.tostring(bestindiv)
        ypred_train = NeoGP.predict!(bestindiv, X, param, buffers) 
        mse_train   = NeoGP.mean_squared_error(y, ypred_train)
        r2_train    = NeoGP.r2_score(y, ypred_train)

        ypred_test  = NeoGP.predict!(bestindiv, X_test, param, buffers_test)
        mse_test    = NeoGP.mean_squared_error(y_test, ypred_test)
        r2_test     = NeoGP.r2_score(y_test, ypred_test)
        
        (nll, func_compl, param_compl) = NeoGP.description_length_terms(bestindiv, buffers)
        dl = nll + func_compl + param_compl
        
        fbf = NeoGP.fractional_bayes_factor(bestindiv, buffers)
        
        println("$gen,$(gp.fevals),$(length(front)),$(bestloss[1]),$(bestobj),$(nll),$(dl),$func_compl,$param_compl,$fbf,$mse_train,$mse_test,$r2_train,$r2_test,$(NeoGP.individual_length(bestindiv)),\"$(best_expr_str)\"")
        nothing
    end
    
    TimerOutputs.disable_timer!(NeoGP.global_timer)
    
    # @time NeoGP.evolve!(gp) # without callback
    NeoGP.initialize!(gp)
    callback() # report for initial population
    @time NeoGP.evolve!(gp, generations, iter_callback = callback)
    
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

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end