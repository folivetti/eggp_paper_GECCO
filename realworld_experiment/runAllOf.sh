#!/bin/bash

datasets30=( chemical_1_tower chemical_2_competition "friction_stat_one-hot" "friction_dyn_one-hot"  )
datasets20=( "flow_stress_phip0.1" nasa_battery_1_10min nasa_battery_2_20min nikuradse_1 nikuradse_2 )

if [ "${1,,}" == "operon" ]; then
   echo "running Operon..."
   for key in "${!datasets30[@]}"; do
     ./runOperon_realworld.sh ${datasets30[$key]} 20 $key &
   done
   for key in "${!datasets20[@]}"; do
     ./runOperon_realworld.sh ${datasets20[$key]} 13 $key &
   done
elif [ "${1,,}" == "pysr" ]; then
   echo "running PySR..."
   for key in "${!datasets30[@]}"; do
     ./runPySR_realworld.sh ${datasets30[$key]} 30 $key &
   done
   for key in "${!datasets20[@]}"; do
     ./runPySR_realworld.sh ${datasets20[$key]} 20 $key &
   done
elif [ "${1,,}" == "tinygp" ]; then
   echo "running tinyGP..."
   for key in "${!datasets30[@]}"; do
     ./runTinyGP_realworld.sh ${datasets30[$key]} 30 &
   done
   for key in "${!datasets20[@]}"; do
     ./runTinyGP_realworld.sh ${datasets20[$key]} 20 &
   done
elif [ "${1,,}" == "eggp_so" ]; then
   echo "running eggp_so..."
   for key in "${!datasets30[@]}"; do
     ./runEggp_so_realworld.sh ${datasets30[$key]} 30 &
   done
   for key in "${!datasets20[@]}"; do
     ./runEggp_so_realworld.sh ${datasets20[$key]} 20 &
   done
elif [ "${1,,}" == "eggp_mo" ]; then
   echo "running eggp_mo..."
   for key in "${!datasets30[@]}"; do
     ./runEggp_mo_realworld.sh ${datasets30[$key]} 30 &
   done
   for key in "${!datasets20[@]}"; do
     ./runEggp_mo_realworld.sh ${datasets20[$key]} 20 &
   done
else
   echo "Invalid algorithm. Usage: ./runAllOf.sh [operon|pysr|tinygp|eggp_so|eggp_mo]"
fi
