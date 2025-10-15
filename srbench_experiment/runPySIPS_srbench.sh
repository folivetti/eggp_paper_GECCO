#!/bin/bash

mkdir -p results/PySIPS_500_10_best/$1

GEN=10
POP=500

for FOLD in {0..2};
do
  for i in {1..10};
  do
    { time python PySIPS_srbench_wrapper.py $1 $GEN $POP $FOLD > results/PySIPS_500_10_best/$1/run_${i}_${FOLD}.csv; } 2>> results/PySIPS_500_10_best/$1/time ;
  done
done



