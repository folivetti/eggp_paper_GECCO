#!/bin/bash

for dir in neogp_*/RAR*; do
# gen,fevals,best_fitness,dl,func_compl,param_compl,nll_train,avg_len,avg_fitness,size,expression
# 1,24879,-1238.6631,-1200.368,-1238.6631,32.95837,5.336665,6.15,Inf,15),"exp(log(abs((((-0.8458461 - -0.8458461) / log(abs(X1))) - (sqrt(abs(X1)) + (X1 * 0.7142719)))))) RARLikelihood{Float32}"
    mlr --csv --fs ',' --hi --prepipe "(tail -n+15 | head -n 100)" \
      rename 1,gen,2,fevals,3,best_fitness,4,dl,5,nll_train,6,func_compl,7,param_compl,8,avg_len,9,avg_fitness,10,size \
      then stats1 -a median,p5,p10,p90,p95 -f nll_train,dl,func_compl,param_compl,size,avg_len -g gen $dir/run*.csv > $dir/stats.csv
done

