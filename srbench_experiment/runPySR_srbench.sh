#!/bin/bash

mkdir -p results/PySR/$1

GEN=200
POP=50

for FOLD in {0..2};
do
  for i in {1..10};
  do
    { time taskset -c $2 python PySR_srbench_wrapper.py $1 $GEN $POP $FOLD > results/PySR/$1/run_${i}_${FOLD}.csv; } 2>> results/PySR/$1/time ;
  done
done



