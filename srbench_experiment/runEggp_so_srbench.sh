#!/bin/bash

mkdir -p results/eggp_so/$1

PM=0.3
PC=0.9
GEN=200
POP=500

for FOLD in {0..2}; 
do

for i in {1..10}; 
do 
	{ time eggp -d datasets/$1_train${FOLD}.csv --test datasets/$1_test${FOLD}.csv -g $GEN --nPop $POP --pm $PM --pc $PC --tournament-size 5 -s 50 -k 3 --loss MSE --opt-iter 50 --opt-retries 2 --non-terminals add,sub,mul,div,exp,log,sin,powerabs,sqrtabs --print-pareto +RTS -N1 -M3G > results/eggp_so/$1/run_${FOLD}_${i}.csv; } 2>> results/eggp_so/$1/time

done
done
