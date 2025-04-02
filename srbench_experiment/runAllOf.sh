#!/bin/bash

datasets=( 192_vineyard 210_cloud 522_pm10 557_analcatdata_apnea1 579_fri_c0_250_5 606_fri_c2_1000_10 650_fri_c0_500_50 678_visualizing_environmental 1028_SWD 1089_USCrime 1193_BNG_lowbwt 1199_BNG_echoMonths )

if [ "${1,,}" == "operon" ]; then
   echo "running Operon..."
   for key in "${!datasets[@]}"; do
     ./runOperon_srbench.sh ${datasets[$key]} $key &
   done
elif [ "${1,,}" == "pysr" ]; then
   echo "running PySR..."
   for key in "${!datasets[@]}"; do
     ./runPySR_srbench.sh ${datasets[$key]} $key &
   done
elif [ "${1,,}" == "tinygp" ]; then
   echo "running tinyGP..."
   for key in "${!datasets[@]}"; do
     ./runTinyGP_srbench.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "eggp_so" ]; then
   echo "running eggp_so..."
   for key in "${!datasets[@]}"; do
     ./runEggp_so_srbench.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "eggp_mo" ]; then
   echo "running eggp_mo..."
   for key in "${!datasets[@]}"; do
     ./runEggp_mo_srbench.sh ${datasets[$key]} &
   done
else
   echo "Invalid algorithm. Usage: ./runAllOf.sh [operon|pysr|tinygp|eggp_so|eggp_mo]"
fi
