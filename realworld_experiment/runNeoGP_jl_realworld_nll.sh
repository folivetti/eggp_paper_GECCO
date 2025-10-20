#!/bin/bash

mkdir -p results/NeoGP_jl_nll_fixedsigma/$1

GEN=300
POP=500
TSIZE=3
LEN=200

for i in {1..10};
do
    { time ~/julia/julia -t 6 --project=../NeoGP/ ../NeoGP/runNeoGP.jl datasets/$1_train.csv target \
      -g $GEN -p $POP -t $TSIZE -m $LEN --objective=nll --sigma $2 --test=datasets/$1_test.csv \
      > results/NeoGP_jl_nll_fixedsigma/$1/run_${i}.csv; }
done  2> results/NeoGP_jl_nll_fixedsigma/$1/time
