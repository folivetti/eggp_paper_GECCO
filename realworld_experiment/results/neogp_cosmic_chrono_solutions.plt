set terminal pdf
set datafile separator comma


f_nll_1(X1)=sqrt(abs((((7472.9946 / X1) + (5537.952 * X1)) * 5.222862) + -61549.824))
f_dl_1(X1)=sqrt((X1 * (X1 * 3882.7366)))
f_dl_2(X1)=sqrt((X1 / ((3.0808554 / 11964.207) / X1)))

set xlabel "z"
set ylabel "H(z)"
set logscale x
set xrange[0.06:2]
set yrange[20:300]
set output "neogp_cosmic_chrono_solutions.pdf"
set samples 400
set key left top
plot "../datasets/CC_Hubble.csv" using 1:2:3 with yerrorbars lc "blue" title "data",\
     f_nll_1(x+1) with lines lw 2 title "f(z) NLL (DL=31.1)",\
     f_dl_1(x+1) with lines lw 2 title "f(z) DL (DL=16.05)",\
     f_dl_2(x+1) with lines lw 2 title "f(z) DL (DL=16.4)"
     
     