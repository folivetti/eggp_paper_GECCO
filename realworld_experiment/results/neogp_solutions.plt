set terminal pdf 
set datafile separator comma

set output 'neogp_solutions.pdf'

set key outside
pdiv(a,b)=a/b
f_nll(X1,X2) = (abs(pdiv((-5.45537 + pdiv(exp((X2 * -3.4496305)), pdiv(-0.0025734694, (X1 * (X1 - X2))))), X1)) ** log(abs(pdiv(8.35965, exp(pdiv(pdiv(-98.397, (-47.442707 + ((X2 - pdiv(35.72903, log(abs(pdiv(pdiv(-1.434033e7, (X1 + 181.36969)), (X1 - (-6.9606865e6 + (X1 * -13.362135)))))))) + -18.109499))), pdiv(X1, X1)))))))
f_dl(X1,X2) = abs((X1 * -0.17747447)) ** -0.26693976
f_eggmo(x0,x1) = sqrt(abs((-0.5519320260323309 * (abs((abs(((x0 / x1) * -0.2718853680692968)) ** -0.6334062513680286)) ** sin(((log(x0) - exp(sqrt(abs(x1)))) * -0.3231455586749189))))))
f_operon(X1,X2) = log(abs(((((175.659882 * X1) ** ((3.255290 * X2) ** (-0.881381))) + (log(abs(((-51.717407) * X1))) / ((-0.840425) * X2))) / (0.034762 * X2))))
set title "Nikuradse 1 Best NLL Solution"
plot '../datasets/nikuradse_1_train.csv' using 2:3:1 with points title 'Training', \
     '../datasets/nikuradse_1_test.csv'  using 2:3:1 with points title 'Test',\
     for [r_k in "15 30.6 60 126 252 507"] f_nll(r_k,x)   lc 0 notitle,\
     keyentry with lines lc 0 title 'Best NLL model'

set title "Nikuradse 1 Best DL Solution"
plot '../datasets/nikuradse_1_train.csv' using 2:3:1 with points title 'Training', \
     '../datasets/nikuradse_1_test.csv'  using 2:3:1 with points title 'Test',\
     for [r_k in "15 30.6 60 126 252 507"] f_dl(r_k,x)   lc 0 notitle,\
     keyentry with lines lc 0 title 'Best DL model'

set title "Nikuradse 1 Best EggMo Solution"
plot '../datasets/nikuradse_1_train.csv' using 2:3:1 with points title 'Training', \
     '../datasets/nikuradse_1_test.csv'  using 2:3:1 with points title 'Test',\
     for [r_k in "15 30.6 60 126 252 507"] f_eggmo(r_k,x)   lc 0 notitle,\
     keyentry with lines lc 0 title 'Best EggMo model'


set title "Nikuradse 1 Best Operon Solution"
plot '../datasets/nikuradse_1_train.csv' using 2:3:1 with points title 'Training', \
     '../datasets/nikuradse_1_test.csv'  using 2:3:1 with points title 'Test',\
     for [r_k in "15 30.6 60 126 252 507"] f_operon(r_k,x)   lc 0 notitle,\
     keyentry with lines lc 0 title 'Best Operon model'



#     '../datasets/nikuradse_1_test.csv'  using 2:(f2($1,$2)) with points title "Test prediction"
#     '../datasets/nikuradse_1_train.csv' using 2:(f1($1,$2)) with points axes x1y2 title "Training prediction",\
#     '../datasets/nikuradse_1_test.csv'  using 2:(f1($1,$2)) with points axes x1y2 title "Test prediction",\
     