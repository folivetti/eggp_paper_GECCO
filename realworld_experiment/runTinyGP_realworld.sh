#!/bin/bash

mkdir -p results/tinyGP/$1

for i in {1..30};
do
   { time tinygp -d datasets/${1}_train.csv:::target --test datasets/${1}_test.csv:::target -g 200 -p 500 --probMut 0.3 --probCx 0.9 --tournament-size 5 --max-size $2 --non-terminals add,sub,mul,div,exp,log,sin,powerabs,sqrtabs > results/tinyGP/$1/run_${i}.csv; } 2>> results/tinyGP/$1/time
done

