#!/bin/bash
set -euo pipefail

# Directory containing network folders
TASK_DIR="./tasks"

# Loop through each network folder in tasks/
for NETWORK_FOLDER in "$TASK_DIR"/*; do
    echo "Checking $NETWORK_FOLDER..."

    # Extract prefixes from task folder names, using find instead of ls
    PREFIXES=$(find "$NETWORK_FOLDER" -maxdepth 1 -type d | awk -F'/' '{print $NF}' | grep -o '^[0-9]\+-[0-9]*')

    # Check for duplicate prefixes
    DUPLICATES=$(echo "$PREFIXES" | sort | uniq -d)

    if [ -z "$DUPLICATES" ]; then
        echo "No duplicates in $NETWORK_FOLDER."
    else
        echo "Duplicate task prefixes found in $NETWORK_FOLDER: $DUPLICATES"
        exit 1
    fi
done

echo "Task prefix uniqueness check completed!"
