#!/bin/bash

datasets=( chemical_1_tower chemical_2_competition "friction_stat_one-hot" "friction_dyn_one-hot" "flow_stress_phip0.1" nasa_battery_1_10min nasa_battery_2_20min nikuradse_1 nikuradse_2 )

if [ "${1,,}" == "operon" ]; then
   echo "running Operon..."
   for key in "${!datasets[@]}"; do
     ./runOperon.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "pysr" ]; then
   echo "running PySR..."
   for key in "${!datasets[@]}"; do
     ./runPySR.sh ${datasets[$key]} $key &
   done
elif [ "${1,,}" == "eggp" ]; then
   echo "running eggp..."
   for key in "${!datasets[@]}"; do
     ./runEggp.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "pysips" ]; then
   echo "running pysips..."
   for key in "${!datasets[@]}"; do
     ./runPySIPS.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "symregg" ]; then
   echo "running symregg..."
   for key in "${!datasets[@]}"; do
     ./runSymRegg.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "random" ]; then
   echo "running random..."
   for key in "${!datasets[@]}"; do
     ./runRandom.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "qlattice" ]; then
   echo "running qlattice..."
   for key in "${!datasets[@]}"; do
     ./runQLattice.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "gomea" ]; then
   echo "running gomea..."
   for key in "${!datasets[@]}"; do
     ./runGOMEA.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "gpzdg" ]; then
   echo "running gpzdg..."
   for key in "${!datasets[@]}"; do
     ./runGPZDG.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "neogp" ]; then
   echo "running neogp..."
   for key in "${!datasets[@]}"; do
     ./runNeoGP.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "rf" ]; then
   echo "running random forest..."
   for key in "${!datasets[@]}"; do
     ./runRF.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "gsgp" ]; then
   echo "running slim gsgp..."
   for key in "${!datasets[@]}"; do
     ./runSlim.sh ${datasets[$key]} &
   done
else
   echo "Invalid algorithm. Usage: ./runAllOf.sh [operon|pysr|eggp|pysips|symregg|random|qlattice|gomea|gpzdg|neogp|rf|gsgp]"
fi
