#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$BASE_DIR/../.."
# shellcheck source=script/utils/get-valid-statuses.sh
source "$BASE_DIR/get-valid-statuses.sh"

# --- Initialize Arrays ---
single_tasks_to_simulate=()
nested_tasks_to_simulate=()

# --- Filter Files ---
filtered_files=$(echo "$FILES_FOUND_BY_GET_VALID_STATUSES" | grep -v "/${TEMPLATES_FOLDER_WITH_NO_TASKS}/")

# --- Search Non-Terminal Tasks ---
search_non_terminal_tasks() {
  local directory
  for file in $filtered_files; do
    if [[ -f "$file" ]]; then
      for status in "${NON_TERMINAL_STATUSES[@]}"; do
        if grep -q "$status" "$file"; then
          directory=$(dirname "$file")
          if [[ -f "$directory/$NESTED_SAFE_TASK_INDICATOR" ]]; then
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

# Define directories to skip - you should add reasons why it's being skipped.
directories_to_skip=(
  "tasks/sep/base-003-fp-granite-prestate" # investigating why this simulation breaks.
  "tasks/sep/013-fp-granite-prestate" # investigating why this simulation breaks.
)

should_skip_directory() {
  local dir="$1"
  for skip_dir in "${directories_to_skip[@]}"; do
    if [[ "$dir" == *"$skip_dir"* ]]; then
      return 0
    fi
  done
  return 1
}

search_non_terminal_tasks

# --- Simulate Single Tasks ---
if [ ${#single_tasks_to_simulate[@]} -eq 0 ]; then
  echo "No single tasks"
else
  echo "Simulating single tasks..."
  echo "Number of single tasks to simulate: ${#single_tasks_to_simulate[@]}"
  export SIMULATE_WITHOUT_LEDGER=1
  for task in "${single_tasks_to_simulate[@]}"; do
    echo "Simulating task: $(basename "$task")"
    current_dir=$(pwd)
    cd "$task" || exit 1
    
    # Check if 'justfile' exists in the current directory it's either an old task
    # that we can skip or a template task which we should also skip.
    if [ -f "justfile" ] || should_skip_directory "$task"; then
      echo "Skipping task: $(basename "$task") - please see simultate-tasks.sh for more information."
    else
      just --dotenv-path "$PWD/.env" --justfile "$ROOT_DIR/single.just" simulate 0
    fi

    cd "$current_dir" || exit 1
  done
fi

# --- Simulate Nested Tasks ---
if [ ${#nested_tasks_to_simulate[@]} -eq 0 ]; then
  echo "No nested tasks"
else
  echo "Simulating nested tasks..."
  echo "Number of nested tasks to simulate: ${#nested_tasks_to_simulate[@]}"
  export SIMULATE_WITHOUT_LEDGER=1
  for task in "${nested_tasks_to_simulate[@]}"; do
    echo "Simulating task: $(basename "$task")"
    current_dir=$(pwd)
    cd "$task" || exit 1

    if [ -f "justfile" ] || should_skip_directory "$task"; then
      echo "Skipping task: $(basename "$task") - please see simultate-tasks.sh to see why."
    else
      just --dotenv-path "$PWD/.env" --justfile "$ROOT_DIR/nested.just" simulate council
      just --dotenv-path "$PWD/.env" --justfile "$ROOT_DIR/nested.just" approve council
      just --dotenv-path "$PWD/.env" --justfile "$ROOT_DIR/nested.just" simulate foundation
      just --dotenv-path "$PWD/.env" --justfile "$ROOT_DIR/nested.just" approve foundation
      just --dotenv-path "$PWD/.env" --justfile "$ROOT_DIR/nested.just" simulate chain-governor
      just --dotenv-path "$PWD/.env" --justfile "$ROOT_DIR/nested.just" approve chain-governor
    fi

    cd "$current_dir" || exit 1
  done
fi
