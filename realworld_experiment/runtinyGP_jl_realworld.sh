#!/bin/bash

mkdir -p results/tinyGP_jl/$1

GEN=100
POP=500
TSIZE=5
LEN=50

for i in {1..30}; 
do 
    { time ~/julia/julia -t 6 --project=../tinyGP/ -L ../tinyGP/tinyGP.jl  ../tinyGP/runTinyGP.jl datasets/$1_train.csv target $GEN $POP $TSIZE $LEN datasets/$1_test.csv > results/tinyGP_jl/$1/run_${i}.csv; } 2> results/tinyGP_jl/$1/time
done
