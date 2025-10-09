set terminal pdf noenhanced font "Arial,10"

set datafile separator comma

set output "linecharts.pdf"

set title "Nikuradse 1"

set ylabel "MSE"
set xlabel "Function evaluations"
set logscale y
# extract fevals,best fitness,avg size
plot for [i=1:30] 'nikuradse_1/run_'.i.'.csv' skip 11 using 2:($3) lc 1 with lines notitle,\
     for [i=1:30] 'nikuradse_1/run_'.i.'.csv' skip 11 using 2:($4) lc 2 with lines notitle

set xlabel "Generations"
plot for [i=1:30] 'nikuradse_1/run_'.i.'.csv' skip 11 using 1:($3) lc 1 with lines notitle,\
     for [i=1:30] 'nikuradse_1/run_'.i.'.csv' skip 11 using 1:($4) lc 2 with lines notitle

set ylabel "Avg. size"
set xlabel "Generations"
unset logscale
# extract generations,best fitness,avg size
plot for [i=1:30] 'nikuradse_1/run_'.i.'.csv' skip 11 using 1:($5) lc 1 with lines notitle