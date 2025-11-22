#!/bin/bash

PNAME="RAR"
mkdir -p results/neogp_nll/${PNAME}
mkdir -p results/neogp_dl/${PNAME}

GEN=100
POP=300
TSIZE=2
LEN=40
NJOBS=32
NTHREADS=4

#~/julia/julia -t 6 --project=NeoGP/ \
#	NeoGP/runNeoGPRAR.jl datasets/RAR.csv -g $GEN -p $POP -t $TSIZE -m $LEN \
#	  --objective=nll --likelihood=unif --threads=$NTHREADS

parallel -j$NJOBS ~/julia/julia -t 4 --project=NeoGP/ \
	NeoGP/runNeoGPRAR.jl datasets/RAR.csv -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=nll --likelihood=unif --threads=$NTHREADS \
	"> results/neogp_nll/${PNAME}/run_{1}.csv" ::: $(seq 1 100)

parallel -j$NJOBS ~/julia/julia -t 4 --project=NeoGP/ \
	NeoGP/runNeoGPRAR.jl datasets/RAR.csv -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=dl --likelihood=unif --threads=$NTHREADS \
	"> results/neogp_dl/${PNAME}/run_{1}.csv" ::: $(seq 1 100)
