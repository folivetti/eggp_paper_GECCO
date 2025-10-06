#!/bin/bash

mkdir -p results/gpzgd/$1

GEN=100000

for FOLD in {0..2}; 
do

for i in {1..10}; 
do 
    { time python GPZDG_srbench_wrapper.py $1 $FOLD > results/gpzgd/$1/run_${i}_${FOLD}.csv; } 2>> results/gpzgd/$1/time ;

done                                                                                                          
done
