#!/bin/bash

mkdir -p results/gomea/$1

GEN=200
POP=500

for i in {1..30};
do
    { time python GOMEA_srbench_wrapper.py $1 $GEN $POP > results/gomea/$1/run_${i}.csv; } 2>> results/gomea/$1/time ;
done



