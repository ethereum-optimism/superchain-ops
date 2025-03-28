#!/bin/bash
set -euo pipefail

# This file finds non-terminal tasks for a specifc network.
# It prints these tasks to the console. Other processes can use this output
# to execute the tasks locally.

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

# Find README.md files for all tasks and process them.
root_dir=$(git rev-parse --show-toplevel)
network=$1

if [[ -z "$network" ]]; then
  echo "Usage: $0 <network>"
  echo "Network is required"
  exit 1
fi

# To enable testing mode set the FETCH_TASKS_TEST_MODE environment variable in your test to true.
is_test=$FETCH_TASKS_TEST_MODE

task_dir="$root_dir/src/improvements/tasks/$network"

if [[ "$is_test" == "true" ]]; then
  task_dir="$root_dir/test/tasks/example/$network"
fi

files=$(find "$task_dir" -type f -name 'README.md')
for file in $files; do
  check_status "$file"
done

# Output the list of tasks to run in a format suitable for the Runner contract
printf '%s\n' "${tasks_to_run[@]}"