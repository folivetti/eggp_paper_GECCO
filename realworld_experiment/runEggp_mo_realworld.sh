#!/bin/bash

mkdir -p results/eggp_mo/$1

PM=0.1
PC=0.9
GEN=200
POP=500

for i in {1..30}; 
do 
	{ time eggp -d datasets/$1_train.csv:::target --test datasets/$1_test.csv:::target -g $GEN --nPop $POP --pm $PM --pc $PC --tournament-size 2 -s 50 -k 2 --loss MSE --opt-iter 10 --opt-retries 1 --non-terminals add,sub,mul,div,exp,log,sin,power,sqrt --simplify > results/eggp_mo/$1/run_${i}.csv; } 2>> results/eggp_mo/$1/time

done
