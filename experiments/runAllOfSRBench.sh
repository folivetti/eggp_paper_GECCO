#!/bin/bash

datasets=( 192_vineyard 210_cloud 522_pm10 557_analcatdata_apnea1 579_fri_c0_250_5 606_fri_c2_1000_10 650_fri_c0_500_50 678_visualizing_environmental 1028_SWD 1089_USCrime 1193_BNG_lowbwt 1199_BNG_echoMonths )

if [ "${1,,}" == "operon" ]; then
   echo "running Operon..."
   for key in "${!datasets[@]}"; do
     ./runOperon.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "pysr" ]; then
   echo "running PySR..."
   for key in "${!datasets[@]}"; do
     ./runPySR.sh ${datasets[$key]} $key srbench &
   done
elif [ "${1,,}" == "eggp" ]; then
   echo "running eggp..."
   for key in "${!datasets[@]}"; do
     ./runEggp.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "pysips" ]; then
   echo "running pysips..."
   for key in "${!datasets[@]}"; do
     ./runPySIPS.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "symregg" ]; then
   echo "running symregg..."
   for key in "${!datasets[@]}"; do
     ./runSymRegg.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "random" ]; then
   echo "running random..."
   for key in "${!datasets[@]}"; do
     ./runRandom.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "qlattice" ]; then
   echo "running qlattice..."
   for key in "${!datasets[@]}"; do
     ./runQLattice.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "gomea" ]; then
   echo "running gomea..."
   for key in "${!datasets[@]}"; do
     ./runGOMEA.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "gpzdg" ]; then
   echo "running gpzdg..."
   for key in "${!datasets[@]}"; do
     ./runGPZDG.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "neogp" ]; then
   echo "running neogp..."
   for key in "${!datasets[@]}"; do
     ./runNeoGP.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "rf" ]; then
   echo "running random forest..."
   for key in "${!datasets[@]}"; do
     ./runRF.sh ${datasets[$key]} srbench &
   done
elif [ "${1,,}" == "gsgp" ]; then
   echo "running slim gsgp..."
   for key in "${!datasets[@]}"; do
     ./runSlim.sh ${datasets[$key]} srbench &
   done
else
   echo "Invalid algorithm. Usage: ./runAllOf.sh [operon|pysr|eggp|pysips|symregg|random|qlattice|gomea|gpzdg|neogp|rf|gsgp]"
fi
