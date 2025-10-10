#!/bin/bash

mkdir -p results/qlattice/$1

GEN=100000

for i in {11..30};
do
    { time python QLattice_realworld_wrapper.py $1 $GEN > results/qlattice/$1/run_${i}.csv; } 2>> results/qlattice/$1/time ;
done



