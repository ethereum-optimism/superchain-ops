#!/bin/bash
set -euo pipefail

# Directory containing network folders
TASK_DIR="./tasks"

# Loop through each network folder in tasks/
for NETWORK_FOLDER in "$TASK_DIR"/*/; do
    echo "Checking $NETWORK_FOLDER..."

    # Find matching directories, return empty string if none found
    PREFIXES=$(find "$NETWORK_FOLDER" -maxdepth 1 -type d -not -path "$NETWORK_FOLDER" | 
               awk -F'/' '{print $NF}' | 
               grep -E '^[0-9]+-[a-zA-Z0-9_]+' || echo "")

    # Extract just the numeric prefix part for duplicate checking
    # This will grab only the "NNN" part
    NUMBER_PREFIXES=$(echo "$PREFIXES" | awk -F'-' '{print $1}' | sort)
    
    # If no matching task directories, continue to next network
    if [ -z "$PREFIXES" ]; then
        echo "No numbered task directories found in $NETWORK_FOLDER."
        continue
    fi

    # Check for duplicate prefixes
    DUPLICATES=$(echo "$NUMBER_PREFIXES" | sort | uniq -d)

    if [ -z "$DUPLICATES" ]; then
        echo "No duplicates in $NETWORK_FOLDER."
    else
        echo "Duplicate task prefixes found in $NETWORK_FOLDER:"
        echo "$DUPLICATES"
        exit 1
    fi
done

echo "Task prefix uniqueness check completed!"