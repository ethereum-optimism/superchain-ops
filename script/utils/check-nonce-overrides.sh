#!/bin/bash
# The directory to search in
search_dir="./tasks"

# Find all .env files in the given directory and its subdirectories
env_files=$(find "$search_dir" -type f -name "*.env")

# Process each .env file
for file in $env_files; do
    echo "Checking file: $file"

    # Process the file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if the line starts with SAFE_NONCE_
        if [[ $line == SAFE_NONCE_* ]]; then
            # Extract the variable name (part before =)
            var_name=$(echo "$line" | cut -d'=' -f1)

            # Check if the variable name contains any lowercase letters
            if [[ "$var_name" =~ [a-z] ]]; then
                echo "Error in $file: $var_name contains lowercase letters"
                exit 1
            fi
        fi
    done < "$file"

    echo "Finished checking: $file"
done

echo "All .env files have been checked. No lowercase letters found in SAFE_NONCE_ variables."
