#!/bin/bash

mkdir -p results/RF/$1


for i in {1..30};
do
  { time python RF_realworld_wrapper.py $1 > results/RF/$1/run_${i}.csv; } 2>> results/RF/$1/time ;
done



