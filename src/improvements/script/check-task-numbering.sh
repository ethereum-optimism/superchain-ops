#!/bin/bash
set -euo pipefail

# This script checks that all task directories have a unique prefix, defined as three digits
# followed by a hyphen (NNN-<some string>)

# Directory containing network folders
task_dir="$1"

# Loop through each network folder in tasks/
for network_folder in "$task_dir"/*/; do
    echo "Checking $network_folder..."

    # Find all task directories
    all_task_dirs=$(find "$network_folder" -maxdepth 1 -type d -not -path "$network_folder" | 
                   awk -F'/' '{print $NF}')
    
    # Find directories that don't match the required pattern
    invalid_prefixes=$(echo "$all_task_dirs" | grep -v -E '^[0-9]{3}-' || echo "")
    if [ -n "$invalid_prefixes" ]; then
        echo "Invalid task prefixes (need NNN-*):"
        echo "$invalid_prefixes"
        exit 1
    fi

    # Extract the numeric prefix
    number_prefixes=$(echo "$all_task_dirs" | sed -E 's/^([0-9]{3})-.*$/\1/' | sort -n)
    
    # If no matching task directories, continue to next network
    if [ -z "$number_prefixes" ]; then
        continue
    fi

    # Check for duplicate prefixes
    duplicates=$(echo "$number_prefixes" | uniq -d)
    echo -e "Duplicates: $duplicates"
    if [ -z "$duplicates" ]; then
        echo "No duplicates in $network_folder."
    else
        echo "Duplicate task prefixes found in $network_folder:"
        echo "$duplicates"
        exit 1
    fi
done

echo "Task prefix uniqueness check completed!"