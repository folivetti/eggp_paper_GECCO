#!/bin/zsh
for file in */run_*.csv; do
    sed -i '/Target encoding for categorical features/d' "$file"
done
