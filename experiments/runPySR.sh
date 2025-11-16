#!/bin/bash

mkdir -p ../report/results/PySR/$1


if [ $3 = "srbench" ]; then
    for FOLD in {0..2};
    do
        for i in {1..10};
        do
            { time taskset -c $2 python PySR_wrapper.py $1 $FOLD > ../report/results/PySR/$1/run_${i}_${FOLD}.csv; } 2>> ../report/results/PySR/$1/time ;
        done 
    done
else
    for i in {1..30};
    do
        { time taskset -c $2 python PySR_wrapper.py $1 > ../report/results/PySR/$1/run_${i}.csv; } 2>> ../report/results/PySR/$1/time ;
    done
fi
