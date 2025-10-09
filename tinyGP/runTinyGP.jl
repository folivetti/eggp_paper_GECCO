# load tinyGP.jl first

function main(args)
    if length(args) < 6 || length(args) > 7
        println("Usage: tinyGP.jl trainingdata.csv targetvariable generations popsize tournamentsize maxlen [ testdataset ]")
        return 
    end
    trainingfilename = args[1]
    targetname = args[2]
    generations = parse(Int, args[3])
    popsize = parse(Int, args[4])
    tsize = parse(Int, args[5])
    maxlen = parse(Int, args[6])
    testdataset = length(args) == 7 ? args[7] : trainingfilename
    
    X_test, y_test = TinyGP.load_dataset(Float64, testdataset, targetname)
    
    gp = TinyGP.Algorithm{Float64}(trainingfilename, targetname, 
        generations=generations, popsize=popsize, maxlen=maxlen, tournamentsize=tsize)

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