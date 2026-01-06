#!/bin/zsh
for file in */run_*.csv; do
    tail -n 2 "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
done
