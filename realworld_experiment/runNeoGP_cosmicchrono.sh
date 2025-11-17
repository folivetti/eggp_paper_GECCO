#!/bin/bash

PNAME="cosmic_chrono"
mkdir -p results/neogp_nll/${PNAME}
mkdir -p results/neogp_dl/${PNAME}

GEN=10
POP=100
TSIZE=2
LEN=20
NJOBS=1
NTHREADS=1

~/julia/julia -t 1 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/CC_Hubble.csv H -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=dl --likelihood=cosmic_chronometers --sigma=Herr --threads=$NTHREADS

parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/CC_Hubble.csv H -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=nll --sigma=Herr --likelihood=cosmic_chronometers \
	"> results/neogp_nll/${PNAME}/run_{1}.csv" ::: $(seq 1 30)
# 
parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/CC_Hubble.csv H -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=dl --sigma=Herr  --likelihood=cosmic_chronometers \
	"> results/neogp_dl/${PNAME}/run_{1}.csv" ::: $(seq 1 30)
