#!/bin/bash

mkdir -p results/slim_gsgp/$1

GEN=10000
POP=500

for i in {1..30};
do 
    { time python GSGP_srbench_wrapper.py $1 $GEN $POP > results/slim_gsgp_10000/$1/run_${i}.csv; } 2>> results/slim_gsgp_10000/$1/time ;
done
