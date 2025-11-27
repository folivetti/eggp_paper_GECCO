#!/bin/bash

PNAME=$1
mkdir -p results/neogp_mapel_nll/$PNAME
mkdir -p results/neogp_mapel_dl/$PNAME

GEN=200
POP=500
TSIZE=2
LEN=100
NJOBS=1

~/julia/julia -t 6 --project=NeoGP/ \
 	NeoGP/runNeoGP.jl datasets/${PNAME}_train.csv target -g 10 -b $POP -t $TSIZE -m $LEN \
 	  --objective=nll --test=datasets/${PNAME}_test.csv --threads=6 

parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/${PNAME}_train.csv target -g $GEN -b $POP -t $TSIZE -m $LEN \
	  --objective=nll --test=datasets/${PNAME}_test.csv \
	"> results/neogp_mapel_nll/${PNAME}/run_{1}.csv" ::: $(seq 1 100)

parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/${PNAME}_train.csv target -g $GEN -b $POP -t $TSIZE -m $LEN \
	  --objective=dl --test=datasets/${PNAME}_test.csv \
	"> results/neogp_mapel_dl/${PNAME}/run_{1}.csv" ::: $(seq 1 100)
