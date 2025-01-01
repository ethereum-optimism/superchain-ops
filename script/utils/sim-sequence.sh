#!/bin/bash

# Simulates a sequence of tasks for a given network by running them against an Anvil
# fork with state overrides disabled.
#
# Usage:
#   ./script/utils/sim-sequence.sh <network> <array-of-task-IDs>
#
# Example:
#   ./script/utils/sim-sequence.sh eth "021 022 base-003 ink-001"

# TODO start an anvil fork and run all simulations against the same node.
# TODO verify the following test cases, push a commit verifying each one has the expected result in CI:
#   - expected to pass: ./script/utils/sim-sequence.sh eth "021 022 base-003 ink-001"
#   - expected to pass: ./script/utils/sim-sequence.sh eth "021 022 base-003"
#   - expected to fail: ./script/utils/sim-sequence.sh eth "021 base-003 ink-001 022"
#   - expected to fail: ./script/utils/sim-sequence.sh eth "021 base-003 ink-001"
#   - expected to fail: ./script/utils/sim-sequence.sh eth "021 025"
#   - expected to fail: create a dir called 021-tmp and run ./script/utils/sim-sequence.sh eth "021 022 base-003 ink-001"
set -euo pipefail

# --- Functions ---

error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Disable state overrides in Simulation.sol. The only state override currently
# disabled is the nonce override.
disable_state_overrides() {
  # Create a backup
  local simulation_file="$root_dir/lib/base-contracts/script/universal/Simulation.sol"
  local backup_file="${simulation_file}.bak"
  cp "$simulation_file" "$backup_file"

  # Comment out lines containing 'state = addNonceOverride'.
  awk '/state = addNonceOverride/ { print "        // " $0; next } { print }' "$simulation_file" > "${simulation_file}.tmp"

  # Replace the original file with the modified version, and ensure cleanup on exit.
  mv "${simulation_file}.tmp" "$simulation_file"
  trap cleanup EXIT
}

cleanup() {
  unset SIMULATE_WITHOUT_LEDGER

  local simulation_file="$root_dir/lib/base-contracts/script/universal/Simulation.sol"
  local backup_file="${simulation_file}.bak"

  if [[ -f "$backup_file" ]]; then
    mv "$backup_file" "$simulation_file"
  fi
}

# Find unique task folder(s) for a given task ID
find_task_folder() {
  local task_id="$1"
  matching_folders=$(find "$task_base_dir" -name "${task_id}*" -type d)

  if [[ -z "$matching_folders" ]]; then
    error_exit "No folder found matching task ID '$task_id'."
  fi

  matching_count=$(echo "$matching_folders" | wc -l)
  if [[ "$matching_count" -gt 1 ]]; then
    echo "Error: Multiple folders found matching task ID '$task_id':" >&2
    echo "$matching_folders" >&2
    exit 1
  fi

  echo "$matching_folders"
}

# --- Main Script ---

# Validate input arguments
if [[ "$#" -ne 2 ]]; then
  echo "Usage: $0 <network> \"<array-of-task-IDs>\"" >&2
  exit 1
fi

network="$1"
task_ids="$2"

# Determine root directory.
base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$base_dir/../.."
task_base_dir="${root_dir}/tasks/${network}"

# Verify task_base_dir exists.
if [[ ! -d "$task_base_dir" ]]; then
  error_exit "Task base directory '$task_base_dir' does not exist."
fi

# Process task IDs.
declare -a task_folders=()
for task_id in $task_ids; do
  matching_folders=$(find_task_folder "$task_id")
  task_folders+=("$matching_folders")
done

echo "Simulating the following tasks in order:"
for task_folder in "${task_folders[@]}"; do
  echo "  $(realpath "$task_folder")"
done

# Disable state overrides and execute tasks.
disable_state_overrides
export SIMULATE_WITHOUT_LEDGER=1
for task_folder in "${task_folders[@]}"; do
  echo -e "\n---- Simulating task $task_folder ----"

  pushd "$task_folder" >/dev/null || error_exit "Failed to navigate to '$task_folder'."

  if [[ -f "${task_folder}/NestedSignFromJson.s.sol" ]]; then
    echo "Task type: nested"
    # TODO This currently hardcodes the council but we should also run as Foundation.
    just --dotenv-path "${PWD}/.env" --justfile "${root_dir}/nested.just" simulate council
  else
    echo "Task type: single"
    just --dotenv-path "${PWD}/.env" --justfile "${root_dir}/single.just" simulate
  fi

  popd >/dev/null || error_exit "Failed to return to previous directory."
done

echo ✅ Success!
