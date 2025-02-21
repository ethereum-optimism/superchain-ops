#!/bin/bash
set -euo pipefail

# Array to store tasks that should be executed
declare -a tasks_to_run=()

# Function to check status and determine if task should be run
check_status() {
  local file_path=$1
  local status_line
  
  # Extract the status line
  status_line=$(awk '/^Status: /{print; exit}' "$file_path")
  
  # If status is not EXECUTED or CANCELLED, add to tasks to run
  if [[ "$status_line" != *"EXECUTED"* ]] && [[ "$status_line" != *"CANCELLED"* ]]; then
    # Get the task directory path
    task_dir=$(dirname "$file_path")
    # Add to array if config.toml exists
    if [[ -f "$task_dir/config.toml" ]]; then
      tasks_to_run+=("$task_dir/config.toml")
    fi
  fi
}

# Find README.md files for all mainnet example tasks and process them. 
# This script only returns mainnet tasks for now. Returning sepolia tasks too would require
# a lot of additional logic in TaskRunner.sol to switch networks.
root_dir=$(git rev-parse --show-toplevel)
network=$1
files=$(find "$root_dir/src/improvements/tasks/example/$network" -type f -name 'README.md')
for file in $files; do
  check_status "$file"
done

# Output the list of tasks to run in a format suitable for the Runner contract
printf '%s\n' "${tasks_to_run[@]}"