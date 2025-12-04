#!/bin/bash

for ffunc in nll dl; do
for dir in neogp_$ffunc/*; do
    mlr --csv --fs ',' --prepipe "(tail -n+11 | head -n 200)" \
	then rename nll_train,nll \
	then stats1 -a median,p5,p10,p90,p95 -f MSE_train,MSE_test,nll,dl,func_compl,param_compl,size,avg_len -g gen $dir/run*.csv* > $dir/stats.csv
done
done
