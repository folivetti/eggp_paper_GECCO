#!/bin/bash

for dir in neogp_*/*; do
    mlr --csv --fs ',' --prepipe "(tail -n+11 | head -n 200)" \
      then stats1 -a median,p5,p10,p90,p95 -f MSE_train,MSE_test,nll_train,dl,size -g gen $dir/run*.csv > $dir/stats.csv
done

