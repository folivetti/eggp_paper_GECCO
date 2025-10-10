#!/bin/bash

mkdir -p results/tinyGP_jl_nll/$1

GEN=100
POP=500
TSIZE=5
LEN=50

for i in {1..30};
do
    { time ~/julia/julia -t 64 --project=../tinyGP/ ../tinyGP/runTinyGP.jl datasets/$1_train.csv target \
      -g $GEN -p $POP -t $TSIZE -m $LEN --objective=nll --test=datasets/$1_test.csv \
      > results/tinyGP_jl_nll/$1/run_${i}.csv; }
done  2> results/tinyGP_jl_nll/$1/time
