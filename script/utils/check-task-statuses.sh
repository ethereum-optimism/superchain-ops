#!/bin/bash
set -euo pipefail

VALID_STATUSES=("DRAFT, NOT READY TO SIGN" "CONTINGENCY TASK, SIGN AS NEEDED" "READY TO SIGN" "SIGNED" "EXECUTED" "CANCELLED")
errors=() # We collect all errors then print them at the end.

# Function to check status and hyperlinks for a single file.
check_status_and_hyperlinks() {
  local file_path=$1
  local status_line
  local is_valid_status=false

  # Extract the status line.
  status_line=$(awk '/^Status: /{print; exit}' "$file_path")
  if [[ -z "$status_line" ]]; then
    errors+=("Error: No 'Status: ' line found in $file_path")
    return
  fi

  # Check if the extracted status line contains any of the valid statuses.
  for valid_status in "${VALID_STATUSES[@]}"; do
    if [[ "$status_line" == *"$valid_status"* ]]; then
      is_valid_status=true
      break
    fi
  done

  if [[ "$is_valid_status" == false ]]; then
    errors+=("Error: Invalid status in '$file_path': $status_line")
    errors+=("Valid statuses are:")
    for valid_status in "${VALID_STATUSES[@]}"; do
      errors+=("- $valid_status")
    done
    return
  fi

  # If the status is EXECUTED, require a link to the execution.
  if [[ "$status_line" == *"EXECUTED"* ]]; then
    if ! echo "$status_line" | grep -q "https\?://"; then
      errors+=("Error: Status is EXECUTED but no link to transaction found in $file_path")
    fi
  fi
}

# Find README.md files for all tasks and process them.
files=$(find ./tasks -type f -path './tasks/*/*/README.md')
for file in $files; do
  check_status_and_hyperlinks "$file"
done

# If there are any errors collected, print them and exit with an error.
if [[ ${#errors[@]} -gt 0 ]]; then
  for error in "${errors[@]}"; do
    echo "$error"
  done
  exit 1
else
  echo "✅ All task statuses are valid"
fi
