#!/bin/bash

mkdir -p results/TabPFN/$1


for i in {1..30};
do
    { time python TabPFN_realworld_wrapper.py $1 > results/TabPFN/$1/run_${i}.csv; } 2>> results/TabPFN/$1/time ;
done



