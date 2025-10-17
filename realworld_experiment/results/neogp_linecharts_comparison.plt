set terminal pdf noenhanced font "Arial,10"

set datafile separator comma
set datafile missing


do for [objfunc in "dl nll_dl"] {

set output "neogp_linecharts".objfunc.".pdf"

### Niku 1
set title "Nikuradse 1"


set logscale y
set yrange [0.0001:0.01]
set ylabel "MSE (test)"
set xlabel "Function evaluations"
# plot for [i=1:30] 'NeoGP_jl_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 2:4 lc 1 with lines notitle,\
#      for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_2/run_'.i.'.csv'  skip 11 using 2:4 lc 2 with lines notitle,\
#      keyentry title "obj: NLL" with lines lc 1,\
#      keyentry title "obj: " . objfunc with lines lc 2


set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/nikuradse_1/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_'.objfunc.'/nikuradse_1/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: ".objfunc  with lines lc 2


set ylabel "DL"
unset logscale y
set yrange [-600:0]
set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/nikuradse_1/run_'.i.'.csv' skip 11 every ::::49 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_1/run_'.i.'.csv'  skip 11 every ::::49 using 1:3 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale y
plot for [i=1:30] 'NeoGP_jl_nll/nikuradse_1/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_1/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale y
plot for [i=1:30] 'NeoGP_jl_nll/nikuradse_1/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_1/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2



### Niku 2
set title "Nikuradse 2"


set logscale y
set yrange [0.001:0.1]
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_2/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [-1000:1000]

unset logscale
set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/nikuradse_2/run_'.i.'.csv' skip 11 every ::::49 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_2/run_'.i.'.csv'  skip 11 every ::::49 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_2/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2



set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_2/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2



### Tower
set title "Chemical 1 Tower"


set logscale y
set yrange [800:10000]
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_1_tower/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
unset yrange
# set yrange [-1000:1000]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/chemical_1_tower/run_'.i.'.csv' skip 11 every ::::49 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_1_tower/run_'.i.'.csv'  skip 11 every ::::49 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2


### Dow Chemical Competition
set title "Chemical 2 Competition"


set logscale y
set yrange [0.01:0.2]
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_2_competition/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [-1000:1000]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/chemical_2_competition/run_'.i.'.csv' skip 11 every ::::49 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_2_competition/run_'.i.'.csv'  skip 11 every ::::49 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2


### Flow stress
set title "Flow stress"

set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/flow_stress_phip0.1/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [6000:18000]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/flow_stress_phip0.1/run_'.i.'.csv' skip 11 every ::::49 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/flow_stress_phip0.1/run_'.i.'.csv'  skip 11 every ::::49 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

### Friction dynamic
set title "Friction dynamic"


set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_dyn_one-hot/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange[-4000:-3000]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/friction_dyn_one-hot/run_'.i.'.csv' skip 11 every ::::49 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_dyn_one-hot/run_'.i.'.csv'  skip 11 every ::::49 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

### Friction static
set title "Friction static"


set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_stat_one-hot/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange[-3600:-2800]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/friction_stat_one-hot/run_'.i.'.csv' skip 11 every ::::49 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_stat_one-hot/run_'.i.'.csv'  skip 11 every ::::49 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

### Battery 1
set title "Battery 1 (10min)"


set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_1_10min/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [2000:3500]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/nasa_battery_1_10min/run_'.i.'.csv' skip 11 every ::::49 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_1_10min/run_'.i.'.csv'  skip 11 every ::::49 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2


### Battery 2
set title "Battery 2 (20min)"


set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_2_20min/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [-3000:0]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'NeoGP_jl_nll/nasa_battery_2_20min/run_'.i.'.csv' skip 11 every ::::49 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_2_20min/run_'.i.'.csv'  skip 11 every ::::49 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'NeoGP_jl_nll/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

}