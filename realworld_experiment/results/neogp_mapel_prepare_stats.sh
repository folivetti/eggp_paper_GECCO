#!/bin/bash

for ds in nikuradse_1 nikuradse_2 chemical_1_tower chemical_2_competition friction_stat_one-hot friction_dyn_one-hot flow_stress_phip0.1 nasa_battery_1_10min nasa_battery_2_20min; do
for ffunc in nll dl; do
	dir="neogp_mapel_$ffunc/$ds"
	mlr --csv --fs ',' --prepipe "(gzip -cd | tail -n+10 | head -n 201)" stats1 -a \
		 median,p5,p10,p90,p95 -f MSE_train,MSE_test,nll,dl,func_compl,param_compl,size,avg_len -g gen $dir/run*.csv.gz > $dir/stats.csv
	done
done

for dir in neogp_mapel_*/RAR_mnr; do
#gen,fevals,best_fitness,dl,nll,func_compl,param_compl,avg_len,avg_fitness,size,expression
    mlr --csv --fs ',' --hi --prepipe "(gzip -cd | tail -n+15 | head -n 100)" \
      rename 1,gen,2,fevals,3,best_fitness,4,dl,5,nll_train,6,func_compl,7,param_compl,8,avg_len,9,avg_fitness,10,size \
      then stats1 -a median,p5,p10,p90,p95 -f nll_train,dl,func_compl,param_compl,size,avg_len -g gen $dir/run*.csv.gz > $dir/stats.csv
done
