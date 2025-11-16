#!/bin/bash

mkdir -p ../report/results/gpzgd/$1

if [ $2 = "srbench" ]; then
    for FOLD in {0..2};
    do
        for i in {1..10};
        do
            { time python GPZDG_wrapper.py $1 $FOLD > ../report/results/gpzgd/$1/run_${i}_${FOLD}.csv; } 2>> ../report/results/gpzgd/$1/time ;
        done 
    done
else
    for i in {1..30};
    do 
        { time python GPZDG_wrapper.py $1 > ../report/results/gpzgd/$1/run_${i}.csv; } 2>> ../report/results/gpzgd/$1/time ;
    done
fi
