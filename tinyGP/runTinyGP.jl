include("tinyGP.jl")

using ArgParse

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
    testdataset = parsed["test"] == "" ? trainingfilename : parsed["test"]

    X_test, y_test = TinyGP.load_dataset(Float64, testdataset, targetname)

    loss_func = paramopt_loss_func = TinyGP.mean_squared_error # default
    @show objective
    if objective == "mse"
        loss_func = paramopt_loss_func = TinyGP.mean_squared_error
    elseif objective == "r2"
        loss_func = paramopt_loss_func = ((-) ∘ TinyGP.r2_score)
    elseif objective == "nll"
        # TODO allow specification of different likelihoods
        # For now we only support Gaussian likelihood with fixed sigma
        loss_func = paramopt_loss_func = TinyGP.negloglik
    elseif objective == "dl"
        paramopt_loss_func = TinyGP.negloglik
        loss_func = ((-) ∘ TinyGP.description_length)
    else
        error("unknown objective function value (allowed values are mse, r2, dl)")
    end
    gp = TinyGP.Algorithm{Float64}(trainingfilename, targetname,
        generations=generations, popsize=popsize, maxlen=maxlen, tournamentsize=tsize, 
        loss_func=loss_func, paramopt_loss_func=paramopt_loss_func)

    println("gen,fevals,mse_train,mse_test,avg_len,best_expr")
    gen = 0
    callback = () -> begin
        gen += 1
        bestfitness,bestidx = findmax(gp.fitness)
        best_expr_str = TinyGP.tostring(gp.pop[bestidx])
        ypred_test = TinyGP.predict(gp.pop[bestidx], X_test)
        println("$gen,$(gp.fevals),$(-bestfitness),$(TinyGP.mean_squared_error(y_test, ypred_test)),$(gp.avg_len),$(best_expr_str)")
    end
    TinyGP.evolve!(gp, iter_callback = callback)
    # print_timer(gp.to)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end