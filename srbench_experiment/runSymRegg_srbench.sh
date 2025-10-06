#!/bin/bash

mkdir -p results/symregg/$1

GEN=100000

for FOLD in {0..2}; 
do

for i in {1..10}; 
do 
	{ time symregg -d datasets/$1_train${FOLD}.csv --test datasets/$1_test${FOLD}.csv -g $GEN -s 50 -k 1 --loss MSE --opt-iter 10 --opt-retries 1 --non-terminals add,sub,mul,div,exp,log,sin,power,sqrt --Simplify -a OnlyRandom > results/symregg/$1/run_${FOLD}_${i}.csv; } 2>> results/symregg/$1/time

done
done
