#!/bin/bash

mkdir -p results/eggp_mo_i10r5/$1

PM=0.1
PC=0.9
GEN=200
POP=500

for FOLD in {0..2}; 
do

for i in {1..10}; 
do 
	{ time eggp -d datasets/$1_train${FOLD}.csv --test datasets/$1_test${FOLD}.csv -g $GEN --nPop $POP --pm $PM --pc $PC --tournament-size 3 -s 50 -k 2 --loss MSE --opt-iter 10 --opt-retries 5 --non-terminals add,sub,mul,div,exp,log,sin,power,sqrt --simplify > results/eggp_mo_i10r5/$1/run_${FOLD}_${i}.csv; } 2>> results/eggp_mo_i10r5/$1/time

done
done
