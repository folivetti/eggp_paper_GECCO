#!/bin/bash

mkdir -p results/operon/$1

GEN=200
POP=500
TS=5

for i in {1..30};
do
    { time python Operon_realworld_wrapper.py $1 > results/operon/$1/run_${i}.csv; } 2>> results/operon/$1/time
done
