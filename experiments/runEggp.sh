#!/bin/bash

mkdir -p ../report/results/eggp/$1

if [ $2 = "srbench" ]; then
    for FOLD in {0..2};
    do
        for i in {1..10};
        do
            { time eggp -d datasets/srbench/$1_train${FOLD}.csv:::target --test datasets/srbench/$1_test${FOLD}.csv:::target -g 200 --nPop 500 --pm 0.1 --pc 0.9 --tournament-size 2 -s 50 -k 2 --loss MSE --opt-iter 50 --opt-retries 2 --non-terminals add,sub,mul,div,exp,log,sin,power,sqrt --simplify > ../report/results/eggp/$1/run_${i}_${FOLD}.csv; } 2>> ../report/results/eggp/$1/time
        done 
    done
else
    for i in {1..30}; 
    do 
        { time eggp -d datasets/realworld/$1_train.csv:::target --test datasets/realworld/$1_test.csv:::target -g 200 --nPop 500 --pm 0.1 --pc 0.9 --tournament-size 2 -s 50 -k 2 --loss MSE --opt-iter 50 --opt-retries 2 --non-terminals add,sub,mul,div,exp,log,sin,power,sqrt --simplify > ../report/results/eggp/$1/run_${i}.csv; } 2>> ../report/results/eggp/$1/time

    done
fi
