#!/bin/bash
set -eo pipefail

# ---------------------------------------------
# Script to detect duplicate numeric prefixes and validate directory naming.
# 
# Checks two conditions:
# 1. All task subdirectories follow 'XXX-' prefix format
# 2. No duplicate numeric prefixes exist within each task group
#
# Example failures:
#   src/improvements/tasks/eth/
#     ├── abc-invalid-name    <-- ❌ invalid prefix format
#     └── 001-duplicate-task
#     └── 001-another-thing   <-- ❌ duplicate prefix
#
# Usage: Run from any directory inside the git repo.
# ---------------------------------------------

root_dir=$(git rev-parse --show-toplevel)
parent_dir="$root_dir/src/improvements/tasks"
exit_code=0

while IFS= read -r -d $'\0' dir; do
    dir_name=$(basename "$dir")
    echo "Checking directory: $dir_name"
    
    invalid_dirs=()
    prefix_map=()
    
    # Process each subdirectory
    while IFS= read -r -d $'\0' subdir; do
        subdir_name=$(basename "$subdir")
        
        # Validate prefix format
        if [[ ! "$subdir_name" =~ ^[0-9]{3}- ]]; then
            invalid_dirs+=("$subdir_name")
            continue
        fi
        
        # Extract prefix and track for duplicates
        prefix="${subdir_name%%-*}"
        prefix_map+=("$prefix")
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -type d -print0)

    # Report invalid directories
    if [ ${#invalid_dirs[@]} -gt 0 ]; then
        echo "❌ Invalid directory names (must start with ###- e.g. 001-task-name):"
        printf '  %s\n' "${invalid_dirs[@]}"
        exit_code=1
    fi

    # Check for duplicates among valid prefixes
    duplicates=$(printf '%s\n' "${prefix_map[@]}" | sort | uniq -d)
    if [[ -n "$duplicates" ]]; then
        echo "❌ Duplicate prefixes found: $duplicates"
        exit_code=1
    fi

    # Success message if no issues
    if [ ${#invalid_dirs[@]} -eq 0 ] && [ -z "$duplicates" ]; then
        echo "✅ All directories valid and no duplicates"
    fi
    
    echo ""
done < <(find "$parent_dir" -mindepth 1 -maxdepth 1 -type d -not -name 'types' -print0)

exit $exit_code
