#!/bin/bash

datasets30=( chemical_1_tower chemical_2_competition "friction_stat_one-hot" "friction_dyn_one-hot"  )
datasets20=( "flow_stress_phip0.1" nasa_battery_1_10min nasa_battery_2_20min nikuradse_1 nikuradse_2 )

if [ "${1,,}" == "operon" ]; then
   echo "running Operon..."
   for key in "${!datasets30[@]}"; do
     ./runOperon_realworld.sh ${datasets30[$key]} &
   done
   for key in "${!datasets20[@]}"; do
     ./runOperon_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "pysr" ]; then
   echo "running PySR..."
   for key in "${!datasets30[@]}"; do
     ./runPySR_realworld.sh ${datasets30[$key]} $key &
   done
   #for key in "${!datasets20[@]}"; do
   #  ./runPySR_realworld.sh ${datasets20[$key]} $key &
   #done
elif [ "${1,,}" == "tinygp" ]; then
   echo "running tinyGP..."
   for key in "${!datasets30[@]}"; do
     ./runTinyGP_realworld.sh ${datasets30[$key]} &
   done
   for key in "${!datasets20[@]}"; do
     ./runTinyGP_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "eggp_so" ]; then
   echo "running eggp_so..."
   for key in "${!datasets30[@]}"; do
     ./runEggp_so_realworld_red.sh ${datasets30[$key]} &
   done
   #for key in "${!datasets20[@]}"; do
   #  ./runEggp_so_realworld_red.sh ${datasets20[$key]} &
   #done
elif [ "${1,,}" == "eggp_mo" ]; then
   echo "running eggp_mo..."
   for key in "${!datasets30[@]}"; do
     ./runEggp_mo_realworld.sh ${datasets30[$key]} &
   done
   for key in "${!datasets20[@]}"; do
     ./runEggp_mo_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "pysips" ]; then
   echo "running pysips..."
   for key in "${!datasets30[@]}"; do
     ./runPySIPS_realworld.sh ${datasets30[$key]} &
   done
   for key in "${!datasets20[@]}"; do
     ./runPySIPS_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "symregg" ]; then
   echo "running symregg..."
   #for key in "${!datasets30[@]}"; do
   #  ./runSymRegg_realworld.sh ${datasets30[$key]} &
   #done
    for key in "${!datasets20[@]}"; do
     ./runSymRegg_realworld.sh ${datasets20[$key]} &
    done
elif [ "${1,,}" == "random" ]; then
   echo "running random..."
   #for key in "${!datasets30[@]}"; do
   #  ./runRandom_realworld.sh ${datasets30[$key]} &
   #done
   for key in "${!datasets20[@]}"; do
     ./runRandom_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "qlattice" ]; then
   echo "running qlattice..."
   for key in "${!datasets30[@]}"; do
     ./runQLattice_realworld.sh ${datasets30[$key]} &
   done
   for key in "${!datasets20[@]}"; do
     ./runQLattice_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "gomea" ]; then
   echo "running gomea..."
   for key in "${!datasets30[@]}"; do
     ./runGOMEA_realworld.sh ${datasets30[$key]} &
   done
   for key in "${!datasets20[@]}"; do
     ./runGOMEA_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "gpzdg" ]; then
   echo "running gpzdg..."
   #for key in "${!datasets30[@]}"; do
   #  ./runGPZDG_realworld.sh ${datasets30[$key]} &
   #done
   for key in "${!datasets20[@]}"; do
     ./runGPZDG_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "neogp" ]; then
   echo "running neogp..."
   for key in "${!datasets30[@]}"; do
     ./runNeoGP_realworld.sh ${datasets30[$key]} &
   done
   for key in "${!datasets20[@]}"; do
     ./runNeoGP_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "rf" ]; then
   echo "running random forest..."
   for key in "${!datasets30[@]}"; do
     ./runRF_realworld.sh ${datasets30[$key]} &
   done
   for key in "${!datasets20[@]}"; do
     ./runRF_realworld.sh ${datasets20[$key]} &
   done
elif [ "${1,,}" == "gsgp" ]; then
   echo "running slim gsgp..."
   for key in "${!datasets30[@]}"; do
     ./runSlim_realworld.sh ${datasets30[$key]} &
   done
   for key in "${!datasets20[@]}"; do
     ./runSlim_realworld.sh ${datasets20[$key]} &
   done
else
   echo "Invalid algorithm. Usage: ./runAllOf.sh [operon|pysr|tinygp|eggp_so|eggp_mo|neogp]"
fi
