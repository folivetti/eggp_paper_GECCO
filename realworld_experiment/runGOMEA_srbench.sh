#!/bin/bash

mkdir -p results/gomea_5/$1

GEN=200
POP=500

for FOLD in {0..2};
do
  for i in {1..10};
  do
    { time python GOMEA_srbench_wrapper.py $1 $GEN $POP $FOLD > results/gomea_5/$1/run_${i}_${FOLD}.csv; } 2>> results/gomea_5/$1/time ;
  done
done



