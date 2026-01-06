#!/bin/bash

PNAME=$1
for pname in $PNAME; do
  mkdir -p ../report/results/neogp_nsga2/$pname
done

NJOBS=8

if [ $2 = "srbench" ]; then
    parallel -S .. -j$NJOBS --return ~/eggp_paper_GECCO/report/results/neogp_nsga2/{3}/run_{2}_{1}.csv \
         (cd ~/eggp_paper_GECCO/experiments/; \
         mkdir -p ../report/results/neogp_nsga2/{3}; \
         ~/julia/julia -t 10 --project=NeoGP/ \
        NeoGP/runNeoGP.jl datasets/srbench/{3}_train{2}.csv target -g 200 -p 500 -t 2 -m 50 \
          --objective=fbf --test=datasets/srbench/{3}_test{2}.csv \
        "> ../report/results/neogp_nsga2/{3}/run_{2}_{1}.csv") ::: $(seq 1 10) ::: $(seq 0 2) ::: $PNAME
else
    parallel -S .. -j$NJOBS --return ~/eggp_paper_GECCO/report/results/neogp_nsga2/{2}/run_{1}.csv \
        (cd ~/eggp_paper_GECCO/experiments/; \
         mkdir -p ../report/results/neogp_nsga2/{2}; \
         ~/julia/julia -t 10 --project=NeoGP/ \
        NeoGP/runNeoGP.jl datasets/realworld/{2}_train.csv target -g 200 -p 500 -t 2 -m 50 \
          --objective=fbf --test=datasets/realworld/{2}_test.csv \
        "> ../report/results/neogp_nsga2/{2}/run_{1}.csv") ::: $(seq 1 30) ::: $PNAME
fi
