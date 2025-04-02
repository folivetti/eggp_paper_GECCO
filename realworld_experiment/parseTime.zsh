#!/bin/zsh
for DSETF in `ls -d results/eggp_so/*/`; do
    DSET=${DSETF#results/eggp_so/}
    for ALG in PySR eggp_so eggp_mo Operon tinyGP; do 
        cat results/$ALG/$DSET/time | grep real | tail -n 30 | awk -F'[\t m,s]' '{ print ($2*60 + $3) }' | awk '{if($1!=""){count++;sum+=$1};y+=$1^2} END{sq=sqrt(y/NR-(sum/NR)^2);sq=sq?sq:0;print dset "," alg "," sum/count}' dset=${DSET%??} alg=$ALG 
    done
done
