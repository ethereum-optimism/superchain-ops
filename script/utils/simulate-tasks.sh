#!/bin/bash
set -euo pipefail

source  ./script/utils/get-valid-statuses.sh

single_tasks_to_simulate=()
nested_tasks_to_simulate=()

# Find README.md files for all tasks and process them.
# Files read from ./script/utils/get-valid-statuses.sh.
# Exclude tasks defined in folder FOLDER_WITH_NO_TASKS.
filtered_files=$(echo "$files" | grep -v "/${FOLDER_WITH_NO_TASKS}/")

search_non_terminal_tasks(){
  local directory
  for file in $filtered_files; do
    # Ensure it's a regular file.
    if [[ -f "$file" ]]; then
      # Read file content and search for any status in the NON_TERMINAL_STATUSES array.
      for status in "${NON_TERMINAL_STATUSES[@]}"; do
        if grep -q "$status" "$file"; then
          directory=$(dirname "$file")
          # Specify if a task is safe or nested.
          if [[ -f "$directory/$IF_THIS_ITS_NESTED" ]]; then
            nested_tasks_to_simulate+=("${file%/README.md}")
          else
            single_tasks_to_simulate+=("${file%/README.md}")
          fi
          break
        fi
      done
    fi
  done
}

search_non_terminal_tasks

if [ ${#single_tasks_to_simulate[@]} -eq 0 ]; then
    echo "No single tasks"
else
    echo "Simulating single tasks..."
    # Prepared acording to ./SINGLE.md

    export SIMULATE_WITHOUT_LEDGER=1

    # Option 1: call simulation command here
    for task in "${single_tasks_to_simulate[@]}"; do
      current_dir=$(pwd)
      cd "$task"
      echo "Simulating task: $task"
      just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate 0
      cd "$current_dir"
    done

    # Option 2: read directly from ./SINGLE.md file
    # md_file="./SINGLE.md"
    # for task in "${single_tasks_to_simulate[@]}"; do
    #   current_dir=$(pwd)
    #   cd "$task"
    #   echo "Simulating task: $task"
    #   awk '
    #     /```shell/ {block_count++; if (block_count == 2) in_block=1; next}
    #     /```/ {if (in_block) exit; in_block=0}
    #     in_block {print}
    #   ' "$md_file" > extracted.sh
    #   SIMULATE_WITHOUT_LEDGER=1
    #   bash extracted.sh
    #   cd "$current_dir"
    # done
fi


if [ ${#nested_tasks_to_simulate[@]} -eq 0 ]; then
    echo "No nested tasks"
else
    echo "Simulating nested tasks..."
    # Prepared acording to ./NESTED.md
    
    export SIMULATE_WITHOUT_LEDGER=1

    for task in "${nested_tasks_to_simulate[@]}"; do
      current_dir=$(pwd)
      cd "$task"
      echo "Simulating task: $task"

      just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate council
      just --dotenv-path $(pwd)/.env --justfile ../../../nested.just approve council

      just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate foundation
      just --dotenv-path $(pwd)/.env --justfile ../../../nested.just approve foundation

      just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate chain-governor
      just --dotenv-path $(pwd)/.env --justfile ../../../nested.just approve chain-governor

      cd "$current_dir"
    done
fi

