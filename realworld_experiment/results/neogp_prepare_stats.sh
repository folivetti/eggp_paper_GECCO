#!/bin/bash

for dir in NeoGP_jl_nll_fixedsigma/*; do
    mlr --csv --fs ',' --prepipe "(tail -n+11 | head -n 200)" \
      then stats1 -a median,p5,p10,p90,p95 -f MSE_train,MSE_test,nll_train,dl,size -g gen $dir/run*.csv > $dir/stats.csv
done

for dir in NeoGP_jl_dl_fixedsigma/*; do
    mlr --csv --fs ',' --prepipe "(tail -n+11 | head -n 200)" \
      then stats1 -a median,p5,p10,p90,p95 -f MSE_train,MSE_test,nll_train,dl,size -g gen $dir/run*.csv > $dir/stats.csv
done
