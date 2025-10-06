#!/bin/bash

mkdir -p results/qlattice/$1

GEN=100000

for FOLD in {0..2};
do
  for i in {1..10};
  do
    { time python QLattice_srbench_wrapper.py $1 $GEN $FOLD > results/qlattice/$1/run_${i}_${FOLD}.csv; } 2>> results/qlattice/$1/time ;
  done
done



