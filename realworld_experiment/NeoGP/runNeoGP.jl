using ArgParse
using TimerOutputs
using DelimitedFiles
using NeoGP

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
            help = "Sigma value for Gaussian likelihood (only used if applicable, e.g., nll or dl objective)"
            arg_type = Float32
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
    sigma = parsed["sigma"]
    nthreads = parsed["threads"]
    testdataset = parsed["test"] == "" ? trainingfilename : parsed["test"]

    X, y = load_dataset(Float32, trainingfilename, targetname)
    X_test, y_test = load_dataset(Float32, testdataset, targetname)

    if objective == "mse"
        if !isnothing(sigma)
            @warn "sigma argument is ignored when using mse objective"
        end
        likelihood = NeoGP.GaussianLikelihood(X, y)
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test)
        loss_func = NeoGP.mean_squared_error
    elseif objective == "r2"
        if !isnothing(sigma)
            @warn "sigma argument is ignored when using mse objective"
        end
        likelihood = NeoGP.GaussianLikelihood(X, y)
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test)
        loss_func = ((-) ∘ NeoGP.r2_score)
    elseif objective == "nll"
        # TODO allow specification of different likelihoods
        likelihood = NeoGP.GaussianLikelihood(X, y, sigma) # optimize sigma
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test, sigma)
        loss_func = NeoGP.negloglik
    elseif objective == "dl"
        # TODO allow specification of different likelihoods
        likelihood = NeoGP.GaussianLikelihood(X, y, sigma) # optimize sigma
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test, sigma)
        loss_func = NeoGP.description_length
    elseif objective == "nll-dl"
        # TODO allow specification of different likelihoods
        likelihood = NeoGP.GaussianLikelihood(X, y, sigma) # optimize sigma
        likelihood_test = NeoGP.GaussianLikelihood(X_test, y_test, sigma)
        loss_func = (params...) -> gp.gen < 0.35 * gp.maxgenerations ? NeoGP.negloglik(params...) : NeoGP.description_length(params...)
    else
        error("unknown objective function value (allowed values are mse, r2, nll, dl)")
    end
    gp = NeoGP.Algorithm(likelihood,
        generations = generations, popsize = popsize, maxlen = maxlen, tournamentsize = tsize,
        loss_func = loss_func, threads = nthreads, 
        functionset = Set([NeoGP.ADD, NeoGP.SUB, NeoGP.MUL, NeoGP.DIV, NeoGP.SIN, NeoGP.EXP, NeoGP.LOGABS, NeoGP.SQRTABS, NeoGP.POWABS]))

    println("gen,fevals,best_fitness,dl,func_compl,param_compl,MSE_train,MSE_test,R2_train,R2_test,nll_train,nll_test,avg_len,avg_fitness,size,Expression")
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
        nll_train   = NeoGP.negloglik(likelihood, ypred_train, bestindiv.likelihood.sigma_err)
        nll_test    = NeoGP.negloglik(likelihood_test, ypred_test, bestindiv.likelihood.sigma_err)
        
        # this is just to produce the terms of the description_length (TODO: simplify)
        (nll, func_compl, param_compl) = NeoGP.description_length_terms(NeoGP.copy(bestindiv))
        dl = nll + func_compl + param_compl
        
        println("$gen,$(gp.fevals),$(-bestfitness),$dl,$func_compl,$param_compl,$mse_train,$mse_test,$r2_train,$r2_test,$nll_train,$nll_test,$(gp.avg_len),$(-gp.favgpop),$(length(bestindiv.program)),\"$(best_expr_str)\"")
        nothing
    end
    TimerOutputs.disable_timer!(gp.to)
    @time NeoGP.evolve!(gp, iter_callback = callback)
    # TimerOutputs.print_timer(gp.to)
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
