#!/bin/bash

datasets=( 192_vineyard 210_cloud 522_pm10 557_analcatdata_apnea1 1028_SWD 1089_USCrime 1193_BNG_lowbwt ) 

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
elif [ "${1,,}" == "eggp_mo2" ]; then
   echo "running eggp_mo2..."
   for key in "${!datasets[@]}"; do
     ./runEggp_mo2_srbench.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "pysips" ]; then
   echo "running pysips..."
   for key in "${!datasets[@]}"; do
     ./runPySIPS_srbench.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "slim" ]; then
   echo "running slim_gsgp..."
   for key in "${!datasets[@]}"; do
     ./runSlim_srbench.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "gomea" ]; then
   echo "running gomea..."
   for key in "${!datasets[@]}"; do
     ./runGOMEA_srbench.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "symregg" ]; then
   echo "running symregg..."
   for key in "${!datasets[@]}"; do
     ./runSymRegg_srbench.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "qlattice" ]; then
   echo "running qlattice..."
   for key in "${!datasets[@]}"; do
     ./runQLattice_srbench.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "gpzdg" ]; then
   echo "running gpzdg..."
   for key in "${!datasets[@]}"; do
     ./runGPZDG_srbench.sh ${datasets[$key]} &
   done
elif [ "${1,,}" == "rf" ]; then
   echo "running rf..."
   for key in "${!datasets[@]}"; do
     ./runRF_srbench.sh ${datasets[$key]} &
   done
else
   echo "Invalid algorithm. Usage: ./runAllOf.sh [operon|pysr|tinygp|eggp_so|eggp_mo|pysips]"
fi
