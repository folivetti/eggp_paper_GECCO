include("tinyGP.jl")

using ArgParse
using TimerOutputs
using DelimitedFiles

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
        println("Usage: tinyGP.jl trainingdata.csv targetvariable [--generations N] [--popsize N] [--tournamentsize N] [--maxlen N] [--objective OBJ] [--testdataset FILE]")
        return
    end

    trainingfilename = parsed["training"]
    targetname = parsed["target"]
    generations = parsed["generations"]
    popsize = parsed["popsize"]
    tsize = parsed["tournamentsize"]
    maxlen = parsed["maxlen"]
    objective = parsed["objective"]
    nthreads = parsed["threads"]
    testdataset = parsed["test"] == "" ? trainingfilename : parsed["test"]

    X, y = load_dataset(Float32, trainingfilename, targetname)
    X_test, y_test = load_dataset(Float32, testdataset, targetname)

    if objective == "mse"
        likelihood = TinyGP.GaussianLikelihood(X, y, 1.0f0)
        likelihood_test = TinyGP.GaussianLikelihood(X_test, y_test, 1.0f0)
        loss_func = TinyGP.mean_squared_error
    elseif objective == "r2"
        likelihood = TinyGP.GaussianLikelihood(X, y, 1.0f0)
        likelihood_test = TinyGP.GaussianLikelihood(X_test, y_test, 1.0f0)
        loss_func = ((-) ∘ TinyGP.r2_score)
    elseif objective == "nll"
        # TODO allow specification of different likelihoods and likelihood parameters
        likelihood = TinyGP.GaussianLikelihood(X, y) # optimize sigma
        likelihood_test = TinyGP.GaussianLikelihood(X_test, y_test)
        loss_func = TinyGP.negloglik
    elseif objective == "dl"
        # TODO allow specification of different likelihoods
        likelihood = TinyGP.GaussianLikelihood(X, y) # optimize sigma
        likelihood_test = TinyGP.GaussianLikelihood(X_test, y_test)
        loss_func = TinyGP.description_length
    else
        error("unknown objective function value (allowed values are mse, r2, dl)")
    end
    gp = TinyGP.Algorithm(likelihood,
        generations = generations, popsize = popsize, maxlen = maxlen, tournamentsize = tsize, 
        loss_func = loss_func, threads = nthreads)

    println("gen,fevals,best_fitness,dl,MSE_train,MSE_test,R2_train,R2_test,nll_train,nll_test,avg_len,size,Expression")
    gen = 0
    callback = () -> begin
        gen += 1
        bestfitness,bestidx = findmax(gp.fitness)
        bestindiv = gp.pop[bestidx]
        best_expr_str = TinyGP.tostring(bestindiv)
        ypred_train = TinyGP.predict(bestindiv, likelihood.X) 
        ypred_test  = TinyGP.predict(bestindiv, X_test)
        mse_train   = TinyGP.mean_squared_error(likelihood.y, ypred_train)
        mse_test    = TinyGP.mean_squared_error(y_test, ypred_test)
        r2_train    = TinyGP.r2_score(likelihood.y, ypred_train)
        r2_test     = TinyGP.r2_score(y_test, ypred_test)
        nll_train   = TinyGP.negloglik(likelihood, ypred_train, bestindiv.likelihood.sigma_err)
        nll_test    = TinyGP.negloglik(likelihood_test, ypred_test, bestindiv.likelihood.sigma_err)
        
        # for evaluation of DL we use the likelihood with optimized sigma
        dl_likelihood = TinyGP.GaussianLikelihood(bestindiv.likelihood.X, bestindiv.likelihood.y, bestindiv.likelihood.sigma_err)
        bestindv_copy   = TinyGP.Individual(copy!(similar(bestindiv.program),bestindiv.program) , dl_likelihood) # copy to avoid modifying the original individual
        dl          = TinyGP.description_length(bestindv_copy)
        
        println("$gen,$(gp.fevals),$(-bestfitness),$dl,$mse_train,$mse_test,$r2_train,$r2_test,$nll_train,$nll_test,$(gp.avg_len),$(length(bestindiv.program)),\"$(best_expr_str)\"")
        nothing
    end
    TimerOutputs.disable_timer!(gp.to)
    @time TinyGP.evolve!(gp, iter_callback = callback)
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