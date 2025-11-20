set terminal pdf

set datafile separator comma

f2_nll(X1)=((X1 - (-0.1365166 - sqrt(abs((((3.4237995 * X1) - (abs(X1) ** 0.59143263)) + 0.03041258))))) - (abs(X1) ** 0.73515725)) # nll=-1288, dl=-1224.40
f3_nll(X1)=((2.703821 + (abs((abs(X1) ** 0.18491772)) ** 3.180001)) / (abs((((abs(X1) ** 2.1215827) + -0.00030065756) / (abs(3.669845) ** 2.3977969))) ** -0.2505678)) # nll=-1294, dl -1243.5597
f4_nll(X1)=sqrt(abs((-0.3850382 * ((abs((X1 + -0.01628182)) ** 0.49394095) + ((-0.73192716 * X1) + ((1.2387838 + X1) - 1.3252368)))))) + X1 # nll: -1314.4 dl: -1259
f5_nll(X1)=(((abs(X1) ** 1.8236951) / (-0.21841796 * X1)) / (1/((abs(X1) ** 0.31053516)) - ((abs((58.721386 * X1)) ** -0.76524365) + 3.6037335))) # nll: -1560 dl: -1500

f1_dl(X1)=(sqrt(abs((-0.022228241 + X1))) + (((X1 ** log(abs(2.826951))) + (0.72457486 * 0.12600218)) * (-1.4072703 + 2.05157))) # dl: -1231 nll: -1280
f2_dl(X1)=abs(((((X1 + (1/((abs(X1) ** 0.72668695)) / 0.360207)) + 30.172329) / sqrt(abs((abs(X1) ** -1.3019626)))) + -3.191896) / -18.014408) # dl: -1529 nll: -1572
f2_dla(X1)=0.0555111 * ((2.77618/abs(X1)**0.726687 + X1 + 30.1723) * abs(X1)**0.650981 - 3.1919)
set output 'rar.pdf'
set logscale y
set logscale x

set xlabel "gbar"
set ylabel "gobs"
set sample 10000
set key right bottom
set xrange [0.0001:1000]
plot '../datasets/RAR.csv' using 'gbar':'gobs' with dots title 'data',\
    f2_nll(x) with line title 'opt nll dl=-1224',\
    f3_nll(x) with line title 'opt nll dl=-1244',\
    f4_nll(x) with line title 'opt nll dl=-1259',\
    f5_nll(x) with line title 'opt nll dl=-1500',\
    f1_dl(x) with line title 'opt dl dl=-1231',\
    f2_dla(x) with line title 'opt dl dl=-1520 !'
    
    
