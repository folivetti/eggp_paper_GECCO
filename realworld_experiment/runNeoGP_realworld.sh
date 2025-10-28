#!/bin/bash

PNAME=$1
mkdir -p results/neogp_nll_freesigma/$PNAME
mkdir -p results/neogp_dl_freesigma/$PNAME

GEN=200
POP=500
TSIZE=2
LEN=100
NJOBS=10

declare -A sigmas # assoc array

sigmas["chemical_1_tower"]="18"
sigmas["chemical_2_competition"]="0.165"
sigmas["flow_stress_phip0.1"]="1.5"
sigmas["friction_dyn_one-hot"]="0.0025"
sigmas["friction_stat_one-hot"]="0.0036"
sigmas["nasa_battery_1_10min"]="31"
sigmas["nasa_battery_2_20min"]="0.15"
sigmas["nikuradse_1"]="0.02"
sigmas["nikuradse_2"]="0.05"

SIGMA=${sigmas[$PNAME]}

parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/${PNAME}_train.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=nll --test=datasets/${PNAME}_test.csv \
	"> results/neogp_nll_freesigma/${PNAME}/run_{1}.csv" ::: $(seq 1 100)

parallel -j$NJOBS ~/julia/julia -t 6 --project=NeoGP/ \
	NeoGP/runNeoGP.jl datasets/${PNAME}_train.csv target -g $GEN -p $POP -t $TSIZE -m $LEN \
	  --objective=dl --test=datasets/${PNAME}_test.csv \
	"> results/neogp_dl_freesigma/${PNAME}/run_{1}.csv" ::: $(seq 1 100)
