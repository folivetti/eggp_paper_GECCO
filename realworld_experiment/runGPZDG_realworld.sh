#!/bin/bash

mkdir -p results/gpzgd/$1

GEN=100000

for i in {1..30};
do 
    { time python GPZDG_srbench_wrapper.py $1 > results/gpzgd/$1/run_${i}.csv; } 2>> results/gpzgd/$1/time ;

done                                                                                                          
