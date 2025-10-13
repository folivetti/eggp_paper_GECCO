#!/bin/bash

mkdir -p results/random5k/$1

GEN=500000

for i in {1..30}; 
do 
    { time symregg -d datasets/$1_train.csv:::target --test datasets/$1_test.csv:::target -g $GEN -s 50 -k 2 --loss MSE --opt-iter 50 --opt-retries 1 --non-terminals add,sub,mul,div,exp,log,sin,power,sqrt --Simplify -a OnlyRandom > results/random5k/$1/run__${i}.csv; } 2>> results/random5k/$1/time          

done                                                                                                          
