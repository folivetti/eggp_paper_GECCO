#!/bin/bash

PNAME=$1
mkdir -p results/neogp/$PNAME

GEN=200
POP=500
TSIZE=2
LEN=50
NJOBS=10

# without parallel for testing
# ~/julia/julia -t 6 --project=NeoGP/ \
# 	NeoGP/runNeoGP.jl datasets/${PNAME}_train.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
# 	  --objective=nll --sigma 1.0 --test=datasets/${PNAME}_test.csv \
# 	> results/neogp/${PNAME}/run_1.csv

# nll with a fixed sigma (e.g. 1.0) is equivalent to optimizing mse (results for nll and dl are however not useful)

parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/${PNAME}_train.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=nll --sigma 1.0 --test=datasets/${PNAME}_test.csv \
	"> results/neogp/${PNAME}/run_{1}.csv" ::: $(seq 1 10)
