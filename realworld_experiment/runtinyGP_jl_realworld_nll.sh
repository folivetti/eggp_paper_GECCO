#!/bin/bash

mkdir -p results/tinyGP_jl_nll/$1

GEN=50
POP=500
TSIZE=3
LEN=50

for i in {1..10};
do
    { time ~/julia/julia -t 12 --project=../tinyGP/ ../tinyGP/runTinyGP.jl datasets/$1_train.csv target \
      -g $GEN -p $POP -t $TSIZE -m $LEN --objective=nll --test=datasets/$1_test.csv \
      > results/tinyGP_jl_nll/$1/run_${i}.csv; }
done  2> results/tinyGP_jl_nll/$1/time
