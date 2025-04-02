#!/bin/bash

mkdir -p results/eggp_mo/$1

for i in {1..30};
do
	{ time eggp -d datasets/$1_train.csv:::target --test datasets/$1_test.csv:::target -g 200 --nPop 500 --pm 0.3 --pc 0.9 --tournament-size 5 -s $2 -k 1 --loss MSE --opt-iter 50 --opt-retries 2 --non-terminals add,sub,mul,div,exp,log,sin,powerabs,sqrtabs --print-pareto --moo +RTS -N1 -M3G > results/eggp_mo/$1/run_${i}.csv; } 2>> results/eggp_mo/$1/time

done
