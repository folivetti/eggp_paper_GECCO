#!/bin/bash

PNAME=$1
mkdir -p ../report/results/neogp/$PNAME

NJOBS=10

# without parallel for testing
# ~/julia/julia -t 6 --project=NeoGP/ \
# 	NeoGP/runNeoGP.jl datasets/${PNAME}_train.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
# 	  --objective=nll --sigma 1.0 --test=datasets/${PNAME}_test.csv \
# 	> ../report/results/neogp/${PNAME}/run_1.csv

# nll with a fixed sigma (e.g. 1.0) is equivalent to optimizing mse (../report/results for nll and dl are however not useful)

if [ $2 = "srbench" ]; then
    parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
        NeoGP/runNeoGP.jl datasets/srbench/${PNAME}_train{2}.csv target -g 200 -p 500 -t 2 -m 50 \
          --objective=nll --sigma 1.0 --test=datasets/srbench/${PNAME}_test{2}.csv \
        "> results/neogp/${PNAME}/run_{2}_{1}.csv" ::: $(seq 1 10) ::: $(seq 0 2)
else
    parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
        NeoGP/runNeoGP.jl datasets/realworld/${PNAME}_train.csv target -g 200 -p 500 -t 2 -m 50 \
          --objective=nll --sigma 1.0 --test=datasets/realworld/${PNAME}_test.csv \
        "> ../report/results/neogp/${PNAME}/run_{1}.csv" ::: $(seq 1 30)
fi
