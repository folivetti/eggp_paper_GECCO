#!/bin/bash

for dir in neogp_*/RAR; do
# gen,fevals,best_fitness,dl,func_compl,param_compl,nll_train,avg_len,avg_fitness,size,expression
    mlr --csv --fs ',' --prepipe "(tail -n+14 | head -n 100)" \
      then stats1 -a median,p5,p10,p90,p95 -f nll_train,dl,func_compl,param_compl,size,avg_len -g gen $dir/run*.csv > $dir/stats.csv
done

