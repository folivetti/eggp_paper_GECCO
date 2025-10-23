#!/bin/bash

PNAME=$1
SIGMA=$2
mkdir -p results/neogp/$PNAME

GEN=200
POP=500
TSIZE=2
LEN=50
NJOBS=10

# without parallel for testing
# ~/julia/julia -t 6 --project=NeoGP/ \
# 	NeoGP/runNeoGP.jl datasets/${PNAME}_train0.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
# 	  --objective=nll --sigma $SIGMA --test=datasets/${PNAME}_test0.csv \
# 	> results/neogp/${PNAME}/run_1.csv

parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/${PNAME}_train{2}.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=nll --sigma $SIGMA --test=datasets/${PNAME}_test{2}.csv \
	"> results/neogp/${PNAME}/run_{2}_{1}.csv" ::: $(seq 1 10) ::: $(seq 0 2)
