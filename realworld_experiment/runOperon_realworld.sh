#!/bin/bash

mkdir -p results/operon/$1


for i in {1..30};
do
 { time taskset -c $3 python Operon_realworld_wrapper.py $1 $2 > results/operon/$1/run_${i}.csv; } 2>> results/operon/$1/time
done

