set terminal pdf noenhanced font "Arial,10"

set datafile separator comma
set datafile missing


set output "neogp_linecharts_nll_vs_dl.pdf"
do for [ds in "nikuradse_1 nikuradse_2 friction_stat_one-hot friction_dyn_one-hot chemical_1_tower chemical_2_competition nasa_battery_1_10min flow_stress_phip0.1 "] {
  set title ds

# gen,MSE_train_median,MSE_train_p5,MSE_train_p95,MSE_test_median,MSE_test_p5,MSE_test_p95,nll_train_median,nll_train_p5,nll_train_p95,dl_median,dl_p5,dl_p95,size_median,size_p5,size_p95

   set key top right
   set logscale y
   # set yrange [0.00001:0.01]
   if (ds eq "nikuradse_1") {
     set yrange [0.0001:0.02]
   } else if (ds eq "nikuradse_2") {
     set yrange [0.001:0.01]
   } else if (ds eq "chemical_1_tower") {
     set yrange [500:10000]
   } else if (ds eq "chemical_2_competition") {
     set yrange [0.01:1]
   } else if (ds eq "friction_stat_one-hot") {
     set yrange [0.00002:0.0001]
   }
   
   set xlabel "Generations"
   
   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.01
   set ylabel "MSE (train)"
   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"MSE_train_p5":"MSE_train_p95" lc 1 with filledcurves fs transparent solid 0.3 title "obj NLL (sigma fixed)",\
        '' using "gen":"MSE_train_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"MSE_train_p5":"MSE_train_p95" lc 2 with filledcurves fs transparent solid 0.3 title "obj DL (sigma fixed)",\
        '' using "gen":"MSE_train_median" lc 2 with lines notitle,\
        
   unset ylabel
   set ytics format ""
   plot 'neogp_nll_freesigma/'.ds.'/stats.csv' using "gen":"MSE_train_p5":"MSE_train_p95" lc 1 with filledcurves fs transparent solid 0.3 title "obj NLL (sigma opt.)",\
        '' using "gen":"MSE_train_median" lc 1 with lines notitle,\
        'neogp_dl_freesigma/'.ds.'/stats.csv'  using "gen":"MSE_train_p5":"MSE_train_p95" lc 2 with filledcurves fs transparent solid 0.3 title "obj DL (sigma opt.)",\
        '' using "gen":"MSE_train_median" lc 2 with lines notitle
   unset multiplot
   
   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.01
   set ylabel "MSE (test)"
   set ytics format "%g"
   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"MSE_test_p5":"MSE_test_p95" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL (sigma fixed)",\
        '' using "gen":"MSE_test_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"MSE_test_p5":"MSE_test_p95" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL (sigma fixed)",\
        '' using "gen":"MSE_test_median" lc 2 with lines notitle,\
        
  unset ylabel
   set ytics format ""
   plot 'neogp_nll_freesigma/'.ds.'/stats.csv' using "gen":"MSE_test_p5":"MSE_test_p95" lc 1 with filledcurves fs transparent solid 0.3 title "obj NLL (sigma opt.)",\
        '' using "gen":"MSE_test_median" lc 1 with lines notitle,\
        'neogp_dl_freesigma/'.ds.'/stats.csv'  using "gen":"MSE_test_p5":"MSE_test_p95" lc 2 with filledcurves fs transparent solid 0.3 title "obj DL (sigma opt.)",\
        '' using "gen":"MSE_test_median" lc 2 with lines notitle
   unset multiplot

   unset logscale y
      
   if (ds eq "nikuradse_1") {
     set yrange [-1000:0]
   } else if (ds eq "nikuradse_2") {
     set yrange [-500:1000]
   } else if (ds eq "chemical_1_tower") {
     set yrange [15000:40000]
   } else if (ds eq "chemical_2_competition") {
     set yrange [-500:1500]
   } else if (ds eq "flow_stress_phip0.1") {
     set yrange [5000:40000]
   } else if (ds eq "friction_dyn_one-hot") {
     set yrange [-5000:5000]
   } else if (ds eq "friction_stat_one-hot") {
     set yrange [-4000:0]
   } else if (ds eq "nasa_battery_1_10min") {
     set yrange [1000:10000]
   }

   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.01

   set ylabel "NLL"
   set ytics format "%g"


   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"nll_train_p5":"nll_train_p95" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL (sigma fixed)",\
        '' using "gen":"nll_train_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"nll_train_p5":"nll_train_p95" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL (sigma fixed)",\
        '' using "gen":"nll_train_median" lc 2 with lines notitle
   unset ylabel
   set ytics format ""
   plot 'neogp_nll_freesigma/'.ds.'/stats.csv' using "gen":"nll_train_p5":"nll_train_p95" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL (sigma opt.)",\
        '' using "gen":"nll_train_median" lc 1 with lines notitle,\
        'neogp_dl_freesigma/'.ds.'/stats.csv'  using "gen":"nll_train_p5":"nll_train_p95" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL (sigma opt.)",\
        '' using "gen":"nll_train_median" lc 2 with lines notitle
   
   unset multiplot


   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.01
   set ylabel "DL"
   set ytics format "%g"

   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"dl_p10":"dl_p90" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL (sigma fixed)",\
        '' using "gen":"dl_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"dl_p10":"dl_p90" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL (sigma fixed)",\
        '' using "gen":"dl_median" lc 2 with lines notitle,\

     unset ylabel
   set ytics format ""

   plot 'neogp_nll_freesigma/'.ds.'/stats.csv' using "gen":"dl_p10":"dl_p90" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL (sigma opt.)",\
        '' using "gen":"dl_median" lc 1 with lines notitle,\
        'neogp_dl_freesigma/'.ds.'/stats.csv'  using "gen":"dl_p10":"dl_p90" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL (sigma opt.)",\
        '' using "gen":"dl_median" lc 2 with lines notitle
 
   unset multiplot
   
   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.01
   set ylabel "Best size"
   set yrange [0:100]
   set ytics format "%g"

   set key bottom right
   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"size_p5":"size_p95" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL (sigma fixed)",\
        '' using "gen":"size_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"size_p5":"size_p95" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL (sigma fixed)",\
        '' using "gen":"size_median" lc 2 with lines notitle,\
     
    unset ylabel
   set ytics format ""
   plot 'neogp_nll_freesigma/'.ds.'/stats.csv' using "gen":"size_p5":"size_p95" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL (sigma opt.)",\
        '' using "gen":"size_median" lc 1 with lines notitle,\
        'neogp_dl_freesigma/'.ds.'/stats.csv'  using "gen":"size_p5":"size_p95" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL (sigma opt.)",\
        '' using "gen":"size_median" lc 2 with lines notitle,\
   
   unset multiplot
   
   unset yrange
   set ytics auto
}

do for [objfunc in "dl_fixedsigma"] {

set output "neogp_linecharts".objfunc.".pdf"



### Niku 1
set title "Nikuradse 1"

set key top right
set logscale y
set yrange [0.00001:0.01]
set ylabel "MSE (train)"

set xlabel "Generations"
plot for [i=1:30] '< cat neogp_nll/nikuradse_1/run_'.i.'.csv | head -n+11 | tail -n 201' using 1:5 lc 1 with lines notitle,\
     for [i=1:30] '< cat NeoGP_jl_'.objfunc.'/nikuradse_1/run_'.i.'.csv | head -n+11 | tail -n 201'  using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: ".objfunc  with lines lc 2

set ylabel "MSE (test)"

set yrange [0.00001:0.5]
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/nikuradse_1/run_'.i.'.csv' skip 10 using 1:6 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_'.objfunc.'/nikuradse_1/run_'.i.'.csv'  skip 10 using 1:6 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: ".objfunc  with lines lc 2



set ylabel "NLL"
set yrange[-1000:1000]
unset logscale y
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/nikuradse_1/run_'.i.'.csv' skip 10 using 1:"nll_train" lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_1/run_'.i.'.csv'  skip 10 using 1:"nll_train" lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2


set ylabel "DL"
unset logscale y
set yrange[-1000:1000]
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/nikuradse_1/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_1/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale y
plot for [i=1:30] 'neogp_nll/nikuradse_1/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_1/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale y
plot for [i=1:30] 'neogp_nll/nikuradse_1/run_'.i.'.csv' skip 11 using 1:13 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_1/run_'.i.'.csv' skip 11 using 1:13 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2



### Niku 2
set title "Nikuradse 2"


set logscale y
set yrange [0.001:0.1]
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_2/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [-400:0]

unset logscale
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_2/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_2/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2



set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nikuradse_2/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2



### Tower
set title "Chemical 1 Tower"


set logscale y
set yrange [800:10000]
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_1_tower/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
unset yrange
# set yrange [-1000:1000]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_1_tower/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_1_tower/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2


### Dow Chemical Competition
set title "Chemical 2 Competition"


set logscale y
set yrange [0.01:0.2]
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_2_competition/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [-100:400]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_2_competition/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/chemical_2_competition/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2


### Flow stress
set title "Flow stress"

set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/flow_stress_phip0.1/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [6000:18000]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/flow_stress_phip0.1/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/flow_stress_phip0.1/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

### Friction dynamic
set title "Friction dynamic"


set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_dyn_one-hot/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange[-4000:-3000]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_dyn_one-hot/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_dyn_one-hot/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

### Friction static
set title "Friction static"


set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_stat_one-hot/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange[-3600:-2800]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_stat_one-hot/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/friction_stat_one-hot/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

### Battery 1
set title "Battery 1 (10min)"


set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_1_10min/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [2000:3500]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_1_10min/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_1_10min/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2


### Battery 2
set title "Battery 2 (20min)"


set logscale y
unset yrange
set ylabel "MSE (test)"
set xlabel "Function evaluations"
set key top right

set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_2_20min/run_'.i.'.csv'  skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "DL"
set yrange [-3000:0]
unset logscale
set xlabel "Generations"
plot for [i=1:30] 'neogp_nll/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_2_20min/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:11 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:11 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

set ylabel "Best size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'neogp_nll/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:12 lc 1 with lines notitle,\
     for [i=1:30] 'NeoGP_jl_' . objfunc .'/nasa_battery_2_20min/run_'.i.'.csv' skip 11 using 1:12 lc 2 with lines notitle,\
     keyentry title "obj: NLL (fixed sigma)" with lines lc 1,\
     keyentry title "obj: " . objfunc with lines lc 2

}