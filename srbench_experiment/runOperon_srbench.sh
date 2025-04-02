#!/bin/bash

mkdir -p results/operon/$1

GEN=200
POP=500
TS=5

for FOLD in {0..2};
do
  for i in {1..10};
  do
    { time taskset -c $2 python Operon_srbench_wrapper.py $1 $FOLD > results/operon/$1/run_${i}_${FOLD}.csv; } 2>> results/operon/$1/time
  done
done
