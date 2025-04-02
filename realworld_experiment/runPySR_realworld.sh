#!/bin/bash

mkdir -p results/PySR/$1

# MAX SIZE : $2
for i in {1..30}; do { time taskset -c $3 python PySR_realworld_wrapper.py $1 200 50 $2 > results/PySR/$1/run_${i}_${FOLD}.csv; } 2>> results/PySR/$1/time ; done



