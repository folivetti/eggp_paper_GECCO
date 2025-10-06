#!/bin/bash

mkdir -p results/RF/$1

for FOLD in {0..2};
do
  for i in {1..10};
  do
    { time python RF_srbench_wrapper.py $1 $FOLD > results/RF/$1/run_${i}_${FOLD}.csv; } 2>> results/RF/$1/time ;
  done
done



