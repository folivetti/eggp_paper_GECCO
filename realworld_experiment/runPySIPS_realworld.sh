#!/bin/bash

mkdir -p results/PySIPS/$1

GEN=10
POP=500

for i in {1..10};
do
    { time python PySIPS_srbench_wrapper.py $1 $GEN $POP > results/PySIPS/$1/run_${i}.csv; } 2>> results/PySIPS/$1/time ;
done



