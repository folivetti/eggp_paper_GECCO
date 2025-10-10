set terminal pdf noenhanced font "Arial,10"

set datafile separator comma

set output "tinygp_linecharts.pdf"

### Niku 2
set title "Nikuradse 2"


set logscale y
set yrange [0.001:0.1]
set ylabel "MSE (test)"
set xlabel "Function evaluations"
# plot for [i=1:30] 'tinyGP_jl_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 2:4 lc 1 with lines notitle,\
#      for [i=1:30] 'tinyGP_jl_dl/nikuradse_2/run_'.i.'.csv'  skip 11 using 2:4 lc 2 with lines notitle,\
#      keyentry title "obj: NLL" with lines lc 1,\
#      keyentry title "obj: DL"  with lines lc 2


set xlabel "Generations"
plot for [i=1:30] 'tinyGP_jl_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 1:4 lc 1 with lines notitle,\
     for [i=1:30] 'tinyGP_jl_dl/nikuradse_2/run_'.i.'.csv'  skip 11 using 1:4 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: DL"  with lines lc 2

set ylabel "Avg. size"
unset yrange
set xlabel "Generations"
set key bottom right
unset logscale
plot for [i=1:30] 'tinyGP_jl_nll/nikuradse_2/run_'.i.'.csv' skip 11 using 1:5 lc 1 with lines notitle,\
     for [i=1:30] 'tinyGP_jl_dl/nikuradse_2/run_'.i.'.csv' skip 11 using 1:5 lc 2 with lines notitle,\
     keyentry title "obj: NLL" with lines lc 1,\
     keyentry title "obj: DL"  with lines lc 2

