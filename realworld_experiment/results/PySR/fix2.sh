#!/bin/bash

# This script modifies all */*.csv files by:
# 1. Adding a double quote (") after the first comma (,)
# 2. Adding a double quote (") before the seventh comma (,) when counting backwards (from the end of the line)

# Check if any files match the pattern
find . -maxdepth 2 -type f -name "*.csv" -print -quit 2>/dev/null
if [ $? -ne 0 ]; then
    echo "No files matching */*.csv found. Exiting."
    exit 1
fi

# Loop through all files matching */*.csv
# The find command is safer than a simple glob for files with spaces or special characters
find . -maxdepth 2 -type f -name "*.csv" | while IFS= read -r file; do
    echo "Processing: $file"
    
    # sed command to perform the two substitutions
    # Explanation of the sed command:
    # 1. 's/^\([^,]*\),/\1\,"/' : Finds the start of the line (^) followed by any characters that are NOT a comma ([^,]*) 
    #    and the first comma (,), and replaces the comma with ',"'.
    #    - \([^,]*\) is captured in group \1 (the text before the first comma).
    #    - The replacement is \1 plus ',"'.
    # 2. 's/\(\([^,]*,\)\{6\}[^,]*\)$/\"\1/' : Finds the end of the line ($) preceded by 
    #    the last six fields (six non-comma groups followed by a comma, plus the final field) 
    #    and prepends a quote (") to this match. This effectively places the quote before 
    #    the 7th comma from the end.
    #    - \(^,]*,\)\{6\} matches six groups of (non-comma characters followed by a comma).
    #    - [^,]* matches the final field (after the 7th-to-last comma).
    #    - $ matches the end of the line.
    #    - The entire matched pattern is captured in group \1 and the replacement is " followed by \1.
    
    # We use 'sed -i' to modify the file in place. Add a backup extension like 'sed -i.bak' 
    # if you want to keep original files as backups.
    #sed -i.bak -E 's/^([^,]*),/\1,"/; s/(([^,]*,\){6}[^,]*)$/"\1/' "$file"
    sed -i -E 's/,"/",/2' "$file"
    
done

echo "Script complete."
