#!/bin/bash

for dir in neogp_*/RAR; do
    mlr --csv --fs ',' --hi --prepipe "(tail -n+15 | head -n 100)" \
      rename 1,gen,2,fevals,3,best_fitness,4,dl,5,nll_train,6,func_compl,7,param_compl,8,avg_len,9,avg_fitness,10,size \
      then stats1 -a median,p5,p10,p90,p95 -f nll_train,dl,func_compl,param_compl,size,avg_len -g gen $dir/run*.csv > $dir/stats.csv
done

for dir in neogp_*/RAR_mnr; do
#gen,fevals,best_fitness,dl,nll,func_compl,param_compl,avg_len,avg_fitness,size,expression
    mlr --csv --fs ',' --hi --prepipe "(tail -n+16 | head -n 100)" \
      rename 1,gen,2,fevals,3,best_fitness,4,dl,5,nll_train,6,func_compl,7,param_compl,8,avg_len,9,avg_fitness,10,size \
      then stats1 -a median,p5,p10,p90,p95 -f nll_train,dl,func_compl,param_compl,size,avg_len -g gen $dir/run*.csv > $dir/stats.csv
done

