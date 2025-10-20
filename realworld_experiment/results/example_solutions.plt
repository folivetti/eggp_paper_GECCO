set terminal pdf 
set datafile separator comma

set output 'example_solutions.pdf'

set key outside
pdiv(a,b)=a/b
f_nll(X1,X2) = (pdiv((pdiv(19705.535, -1513.3252) - pdiv(X2, (pdiv(X2, pdiv(X1, pdiv(pdiv(log(abs((X2 + pdiv(-178042.42, 23382.623)))), 0.004164947), (exp(-418.20148) - 0.0015296378)))) * (pdiv(pdiv(log(abs((X1 + -21.17094))), 291190.9), (pdiv(35.920033, X1) - (4.2710896 - X2))) + exp(pdiv(pdiv(341481.84, (((pdiv((pdiv((7550.242 + X1), 5444.6816) - -310419.06), ((-118.74024 + 18.409668) - X1)) + 30188.436) + -77566.07) - -41961.336)), X2)))))), ((-33.250134 + (47.372906 - pdiv(((111580.16 - log(abs(X1))) - X1), ((3497.4644 + (385.37195 - (X2 * 115.67391))) - X1)))) - X1)) + 0.420019)
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
     