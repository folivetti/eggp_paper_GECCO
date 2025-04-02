#!/bin/bash

mkdir -p results/tinyGP/$1

GEN=200
POP=500
TS=5

for FOLD in {0..2};
do

for i in {1..10};
  do
     { time tinygp -d datasets/${1}_train${FOLD}.csv --test datasets/${1}_test${FOLD}.csv -g $GEN -p $POP --probMut 0.3 --probCx 0.9 --tournament-size $TS --max-size 50 --non-terminals add,sub,mul,div,exp,log,sin,powerabs,sqrtabs > results/tinyGP/$1/run_${i}_${FOLD}.csv; } 2>> results/tinyGP/$1/time
  done
done
