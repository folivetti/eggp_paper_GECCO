#!/bin/bash

mkdir -p results/slim_gsgp_10000/$1

GEN=10000
POP=500

for FOLD in {0..2}; 
do

for i in {1..10}; 
do 
    { time python GSGP_srbench_wrapper.py $1 $GEN $POP $FOLD > results/slim_gsgp_10000/$1/run_${i}_${FOLD}.csv; } 2>> results/slim_gsgp_10000/$1/time ;

done
done
