#!/bin/bash

PNAME=$1
mkdir -p results/neogp_nll/$PNAME

GEN=200
POP=500
TSIZE=2
LEN=50
NJOBS=1

# without parallel for testing
# ~/julia/julia -t 6 --project=NeoGP/ \
# 	NeoGP/runNeoGP.jl datasets/${PNAME}_train0.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
# 	  --objective=nll --sigma 1.0 --test=datasets/${PNAME}_test0.csv \
# 	> results/neogp/${PNAME}/run_1.csv

# nll with a fixed sigma (e.g. 1.0) is equivalent to optimizing mse (results for nll and dl are however not useful)

parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/${PNAME}_train{2}.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=nll --test=datasets/${PNAME}_test{2}.csv \
	"> results/neogp_nll/${PNAME}/run_{2}_{1}.csv" ::: $(seq 1 10) ::: $(seq 0 2)

parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/${PNAME}_train{2}.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=dl --test=datasets/${PNAME}_test{2}.csv \
	"> results/neogp_dl/${PNAME}/run_{2}_{1}.csv" ::: $(seq 1 10) ::: $(seq 0 2)
