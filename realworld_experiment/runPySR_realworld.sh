#!/bin/bash

mkdir -p results/PySR/$1

GEN=200
POP=50

for i in {1..30};
do
    { time taskset -c $2 python PySR_realworld_wrapper.py $1 $GEN $POP > results/PySR/$1/run_${i}.csv; } 2>> results/PySR/$1/time ;
done



