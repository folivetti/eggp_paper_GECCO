#!/bin/bash

mkdir -p results/NeoGP_jl_dl/$1

GEN=50
POP=500
TSIZE=3
LEN=50

for i in {1..10};
do
    { time ~/julia/julia -t 12 --project=../NeoGP/ ../NeoGP/runNeoGP.jl datasets/$1_train.csv target \
      -g $GEN -p $POP -t $TSIZE -m $LEN --objective=dl --test=datasets/$1_test.csv \
      > results/NeoGP_jl_dl/$1/run_${i}.csv; }
done  2> results/NeoGP_jl_dl/$1/time
