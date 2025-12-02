set terminal pdf noenhanced font "Arial,10"

set datafile separator comma
set datafile missing


set output "neogp_linecharts_nll_vs_dl.pdf"

# neogp and neogp_mapel
do for [ds in "RAR RAR_mnr nikuradse_1 nikuradse_2"] {
     print ds
   set title ds
   set key top right
   
   set logscale y
   if (ds ne "RAR" && ds ne "RAR_mnr") {
      # set yrange [0.00001:0.01]
      if (ds eq "nikuradse_1") {
        set yrange [0.00001:0.02]
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
      set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.1
      set ylabel "MSE (train)"
      plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"MSE_train_p5":"MSE_train_p95" lc 1 with filledcurves fs transparent solid 0.3 title "obj NLL",\
           '' using "gen":"MSE_train_median" lc 1 with lines notitle,\
           'neogp_dl/'.ds.'/stats.csv'  using "gen":"MSE_train_p5":"MSE_train_p95" lc 2 with filledcurves fs transparent solid 0.3 title "obj DL",\
           '' using "gen":"MSE_train_median" lc 2 with lines notitle,\
           'neogp_mapel_nll/'.ds.'/stats.csv' using "gen":"MSE_train_p5":"MSE_train_p95" lc 3 with filledcurves fs transparent solid 0.3 title "obj NLL (MAP-El.)",\
           '' using "gen":"MSE_train_median" lc 3 with lines notitle,\
           'neogp_mapel_dl/'.ds.'/stats.csv'  using "gen":"MSE_train_p5":"MSE_train_p95" lc 42 with filledcurves fs transparent solid 0.3 title "obj DL (MAP-El.)",\
           '' using "gen":"MSE_train_median" lc 4 with lines notitle
      
      
      set ylabel "MSE (test)"
      set ytics format "%g"
      plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"MSE_test_p5":"MSE_test_p95" lc 1 with filledcurves fs transparent solid 0.3 title "obj NLL",\
           '' using "gen":"MSE_test_median" lc 1 with lines notitle,\
           'neogp_dl/'.ds.'/stats.csv'  using "gen":"MSE_test_p5":"MSE_test_p95" lc 2 with filledcurves fs transparent solid 0.3 title "obj DL",\
           '' using "gen":"MSE_test_median" lc 2 with lines notitle,\
           'neogp_mapel_nll/'.ds.'/stats.csv' using "gen":"MSE_test_p5":"MSE_test_p95" lc 1 with filledcurves fs transparent solid 0.3 title "obj NLL (MAP-El)",\
           '' using "gen":"MSE_test_median" lc 1 with lines notitle,\
           'neogp_mapel_dl/'.ds.'/stats.csv'  using "gen":"MSE_test_p5":"MSE_test_p95" lc 2 with filledcurves fs transparent solid 0.3 title "obj DL (MAP-El)",\
           '' using "gen":"MSE_test_median" lc 2 with lines notitle
      unset multiplot

  }

   unset logscale y
   
   ymin=0
   ymax=1
   if (ds eq "RAR") {
     ymin=-1600; ymax=-1000
   } else if (ds eq "RAR_mnr") {
     ymin=-1100; ymax=-800
   } else if (ds eq "nikuradse_1") {
     ymin=-1000; ymax=0
   } else if (ds eq "nikuradse_2") {
     ymin=-500; ymax=1000
   }
 
   set yrange[ymin:ymax]

   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.1

   set ylabel "NLL"
   set ytics format "%g"

   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"nll_train_p5":"nll_train_p95" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"nll_train_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"nll_train_p5":"nll_train_p95" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"nll_train_median" lc 2 with lines notitle,\
        'neogp_mapel_nll/'.ds.'/stats.csv' using "gen":"nll_train_p5":"nll_train_p95" lc 3 with  filledcurves fs transparent solid 0.3  title "obj NLL (MAP-El)",\
        '' using "gen":"nll_train_median" lc 3 with lines notitle,\
        'neogp_mapel_dl/'.ds.'/stats.csv'  using "gen":"nll_train_p5":"nll_train_p95" lc 4 with  filledcurves fs transparent solid 0.3  title "obj DL (MAP-El)",\
        '' using "gen":"nll_train_median" lc 4 with lines notitle



   
   set ylabel "DL"
   set ytics format "%g"

   filter(x)= (x >= ymax) ? ymax : x
   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"dl_p5":(filter(column("dl_p95"))) lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"dl_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"dl_p5":(filter(column("dl_p95"))) lc 2 with filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"dl_median" lc 2 with lines notitle,\
        'neogp_mapel_nll/'.ds.'/stats.csv' using "gen":"dl_p5":(filter(column("dl_p95"))) lc 3 with  filledcurves fs transparent solid 0.3  title "obj NLL (MAP-El)",\
        '' using "gen":"dl_median" lc 3 with lines notitle,\
        'neogp_mapel_dl/'.ds.'/stats.csv'  using "gen":"dl_p5":(filter(column("dl_p95"))) lc 4 with filledcurves fs transparent solid 0.3  title "obj DL (MAP-El)",\
        '' using "gen":"dl_median" lc 4 with lines notitle

  unset multiplot
     
   unset yrange

   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.10
   set ylabel "Function complexity"
   set ytics format "%g"
   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"func_compl_p10":"func_compl_p90" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"func_compl_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"func_compl_p10":"func_compl_p90" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"func_compl_median" lc 2 with lines notitle,\
        'neogp_mapel_nll/'.ds.'/stats.csv' using "gen":"func_compl_p10":"func_compl_p90" lc 3 with  filledcurves fs transparent solid 0.3  title "obj NLL (MAP-El)",\
        '' using "gen":"func_compl_median" lc 3 with lines notitle,\
        'neogp_mapel_dl/'.ds.'/stats.csv'  using "gen":"func_compl_p10":"func_compl_p90" lc 4 with  filledcurves fs transparent solid 0.3  title "obj DL (MAP-El)",\
        '' using "gen":"func_compl_median" lc 4 with lines notitle

 
   ymin=0; ymax=100; set yrange[ymin:ymax]
   set ylabel "Parameter complexity"
   set ytics format "%g"

   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"param_compl_p10":(filter(column("param_compl_p90"))) lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"param_compl_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"param_compl_p10":(filter(column("param_compl_p90"))) lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"param_compl_median" lc 2 with lines notitle,\
        'neogp_mapel_nll/'.ds.'/stats.csv' using "gen":"param_compl_p10":(filter(column("param_compl_p90"))) lc 3 with  filledcurves fs transparent solid 0.3  title "obj NLL (MAP-El)",\
        '' using "gen":"param_compl_median" lc 3 with lines notitle,\
        'neogp_mapel_dl/'.ds.'/stats.csv'  using "gen":"param_compl_p10":(filter(column("param_compl_p90"))) lc 4 with  filledcurves fs transparent solid 0.3  title "obj DL (MAP-El)",\
        '' using "gen":"param_compl_median" lc 4 with lines notitle
   unset multiplot
 
    set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.1
   set ylabel "Best size"
   ymin=0; ymax=100; set yrange[ymin:ymax]
   set ytics format "%g"

   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"size_p5":(filter(column("size_p95"))) lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"size_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"size_p5":(filter(column("size_p95"))) lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"size_median" lc 2 with lines notitle,\
        'neogp_mapel_nll/'.ds.'/stats.csv' using "gen":"size_p5":(filter(column("size_p95"))) lc 3 with  filledcurves fs transparent solid 0.3  title "obj NLL (MAP-El)",\
        '' using "gen":"size_median" lc 3 with lines notitle,\
        'neogp_mapel_dl/'.ds.'/stats.csv'  using "gen":"size_p5":(filter(column("size_p95"))) lc 4 with  filledcurves fs transparent solid 0.3  title "obj DL (MAP-El)",\
        '' using "gen":"size_median" lc 4 with lines notitle
   
   set ylabel "Average size"
   ymin=0; ymax=100; set yrange[ymin:ymax]
   set ytics format "%g"

   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"avg_len_p5":(filter(column("avg_len_p95"))) lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"avg_len_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"avg_len_p5":(filter(column("avg_len_p95"))) lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"avg_len_median" lc 2 with lines notitle,\
        'neogp_mapel_nll/'.ds.'/stats.csv' using "gen":"avg_len_p5":(filter(column("avg_len_p95"))) lc 3 with  filledcurves fs transparent solid 0.3  title "obj NLL (MAP-El)",\
        '' using "gen":"avg_len_median" lc 3 with lines notitle,\
        'neogp_mapel_dl/'.ds.'/stats.csv'  using "gen":"avg_len_p5":(filter(column("avg_len_p95"))) lc 4 with  filledcurves fs transparent solid 0.3  title "obj DL (MAP-El)",\
        '' using "gen":"avg_len_median" lc 4 with lines notitle
        
   unset multiplot
   unset yrange
   set ytics format "%g"
}

# just neogp
do for [ds in "chemical_1_tower chemical_2_competition friction_stat_one-hot friction_dyn_one-hot nasa_battery_1_10min flow_stress_phip0.1"] {
   print ds
   set title ds
   set key top right
   
   set logscale y
   # set yrange [0.00001:0.01]
   if (ds eq "nikuradse_1") {
     set yrange [0.00001:0.02]
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
   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.1
   set ylabel "MSE (train)"
   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"MSE_train_p5":"MSE_train_p95" lc 1 with filledcurves fs transparent solid 0.3 title "obj NLL",\
        '' using "gen":"MSE_train_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"MSE_train_p5":"MSE_train_p95" lc 2 with filledcurves fs transparent solid 0.3 title "obj DL",\
        '' using "gen":"MSE_train_median" lc 2 with lines notitle
   set ylabel "MSE (test)"
   set ytics format "%g"
   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"MSE_test_p5":"MSE_test_p95" lc 1 with filledcurves fs transparent solid 0.3 title "obj NLL",\
        '' using "gen":"MSE_test_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"MSE_test_p5":"MSE_test_p95" lc 2 with filledcurves fs transparent solid 0.3 title "obj DL",\
        '' using "gen":"MSE_test_median" lc 2 with lines notitle
   unset multiplot

   unset logscale y
   
   ymin=0
   ymax=1
   if (ds eq "chemical_1_tower") {
     ymin=15000; ymax=40000
   } else if (ds eq "chemical_2_competition") {
     ymin=-500; ymax=1500
   } else if (ds eq "flow_stress_phip0.1") {
     ymin=5000; ymax=40000
   } else if (ds eq "friction_dyn_one-hot") {
     ymin=-5000; ymax=5000
   } else if (ds eq "friction_stat_one-hot") {
     ymin=-4000; ymax=0
   } else if (ds eq "nasa_battery_1_10min") {
     ymin=1000; ymax=10000
   }
 
   set yrange[ymin:ymax]

   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.1

   set ylabel "NLL"
   set ytics format "%g"

   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"nll_train_p5":"nll_train_p95" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"nll_train_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"nll_train_p5":"nll_train_p95" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"nll_train_median" lc 2 with lines notitle


   
   set ylabel "DL"
   set ytics format "%g"

   filter(x)= (x >= ymax) ? ymax : x
   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"dl_p5":(filter(column("dl_p95"))) lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"dl_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"dl_p5":(filter(column("dl_p95"))) lc 2 with filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"dl_median" lc 2 with lines notitle

  unset multiplot
     
   unset yrange

   set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.10
   set ylabel "Function complexity"
   set ytics format "%g"
   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"func_compl_p10":"func_compl_p90" lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"func_compl_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"func_compl_p10":"func_compl_p90" lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"func_compl_median" lc 2 with lines notitle

 
   ymin=0; ymax=100; set yrange[ymin:ymax]
   set ylabel "Parameter complexity"
   set ytics format "%g"

   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"param_compl_p10":(filter(column("param_compl_p90"))) lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"param_compl_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"param_compl_p10":(filter(column("param_compl_p90"))) lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"param_compl_median" lc 2 with lines notitle
   unset multiplot
 
    set multiplot layout 1,2 margins 0.15,0.95,0.1,0.9 spacing 0.1
   set ylabel "Best size"
   ymin=0; ymax=100; set yrange[ymin:ymax]
   set ytics format "%g"

   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"size_p5":(filter(column("size_p95"))) lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"size_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"size_p5":(filter(column("size_p95"))) lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"size_median" lc 2 with lines notitle
   
   set ylabel "Average size"
   ymin=0; ymax=100; set yrange[ymin:ymax]
   set ytics format "%g"

   plot 'neogp_nll/'.ds.'/stats.csv' using "gen":"avg_len_p5":(filter(column("avg_len_p95"))) lc 1 with  filledcurves fs transparent solid 0.3  title "obj NLL",\
        '' using "gen":"avg_len_median" lc 1 with lines notitle,\
        'neogp_dl/'.ds.'/stats.csv'  using "gen":"avg_len_p5":(filter(column("avg_len_p95"))) lc 2 with  filledcurves fs transparent solid 0.3  title "obj DL",\
        '' using "gen":"avg_len_median" lc 2 with lines notitle
        
   unset multiplot
   unset yrange
   set ytics format "%g"
}
