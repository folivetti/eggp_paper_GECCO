#!/bin/bash

# Title: CSV Warning Line Remover
# Description: Finds all CSV files in subdirectories (*/*.csv) and removes
# lines containing a specific SymPy evaluation warning.

# Define the exact warning string to be removed
# We must escape the brackets [ and ! because they have special meaning in regex.
WARNING_PATTERN="\[!\] Warning: failed to evaluate sympy model, returning NaN as prediction"

# Check if any files match the pattern *
shopt -s nullglob # Ensure the loop doesn't run if no files match the pattern

echo "Starting cleanup process for all files matching */*.csv..."
echo "--------------------------------------------------------"

# Loop through all files matching the pattern */*.csv
# The pattern will match files like "data/run1.csv", "logs/test.csv", etc.
for file in */*.csv
do
    # Check if the file exists (important if 'nullglob' is not set, but good practice)
    if [ -f "$file" ]; then
        echo "Processing: $file"

        # Use sed to delete lines containing the exact warning pattern.
        # -i.bak: Edits the file in place and creates a backup with the .bak extension.
        # /.../d: This is the 'address' command in sed; it deletes the matched line.
        # The delimiter / is used, so the internal [] must be escaped.
        sed -i.bak "/${WARNING_PATTERN}/d" "$file"

        # Optional: Print how many lines were removed
        # (Compare line count of original vs. new file)
        original_lines=$(wc -l < "${file}.bak")
        new_lines=$(wc -l < "$file")
        removed_count=$((original_lines - new_lines))

        if [ "$removed_count" -gt 0 ]; then
            echo "  -> Successfully removed $removed_count warning lines."
        else
            echo "  -> No warning lines found in this file."
        fi
    fi
done

echo "--------------------------------------------------------"
echo "Cleanup complete. Original files backed up with .bak extension."
echo "If the results look correct, you can delete the backups using: find . -name '*.bak' -delete"

# Restore default shell option
shopt -u nullglob
