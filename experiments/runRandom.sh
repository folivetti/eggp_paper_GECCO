#!/bin/bash

mkdir -p ../report/results/random/$1


if [ $2 = "srbench" ]; then
    for FOLD in {0..2};
    do
        for i in {1..10};
        do
            { time symregg -d datasets/srbench/$1_train${FOLD}.csv:::target --test datasets/srbench/$1_test${FOLD}.csv:::target -g 100000 -s 50 -k 2 --loss MSE --opt-iter 50 --opt-retries 1 --non-terminals add,sub,mul,div,exp,log,sin,power,sqrt --Simplify -a OnlyRandom > ../report/results/random/$1/run_${i}_${FOLD}.csv; } 2>> ../report/results/random/$1/time
        done 
    done
else
    for i in {1..30}; 
    do 
        { time symregg -d datasets/realworld/$1_train.csv:::target --test datasets/realworld/$1_test.csv:::target -g 100000 -s 50 -k 2 --loss MSE --opt-iter 50 --opt-retries 1 --non-terminals add,sub,mul,div,exp,log,sin,power,sqrt --Simplify -a OnlyRandom > ../report/results/random/$1/run_${i}.csv; } 2>> ../report/results/random/$1/time

    done                                                                                                          
fi
