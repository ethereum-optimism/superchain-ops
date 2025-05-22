#!/bin/bash
set -euo pipefail

# This script scans all config.toml files under src/improvements/tasks,
# and makes sure that any string 'value' in [stateOverrides] is a 66-character hex string (0x...).
# Exits with an error if any invalid value is found.
#
# Passing state overrides to a task can cause undefined behavior if the value is encoded incorrectly.
# This script is a sanity check to catch any such errors.

root_dir=$(git rev-parse --show-toplevel)
parent_dir="$root_dir/src/improvements/tasks"

while IFS= read -r -d $'\0' dir; do
    dir_name=$(basename "$dir")
    echo "Checking directory: $dir_name"
    
    while IFS= read -r -d $'\0' subdir; do
        subdir_name=$(basename "$subdir")
        echo "  Checking subdirectory: $subdir_name"

        config_toml="$subdir/config.toml"
        if [ ! -f "$config_toml" ]; then
            echo "    No config.toml file found in $subdir_name, skipping."
            continue
        fi

        # Use the correct flag for TOML input
        values=$(yq -p toml '.stateOverrides.*[].value | select(tag == "!!str")' "$config_toml" 2>/dev/null || true)

        if [ -z "$values" ]; then
            echo "    No string 'value' entries found in $subdir_name, skipping validation."
            continue
        fi

        # Validate each extracted string value
        while IFS= read -r value; do
            if [[ "$value" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
                echo "    Valid value: $value"
            else
                echo "    ERROR: Invalid value detected: $value"
                echo "    Validation failed in $config_toml"
                exit 1
            fi
        done <<< "$values"

    done < <(find "$dir" -maxdepth 1 -mindepth 1 -type d -print0)

    echo ""
done < <(find "$parent_dir" -mindepth 1 -maxdepth 1 -type d -not -name 'types' -print0)

echo "All validations passed successfully."
