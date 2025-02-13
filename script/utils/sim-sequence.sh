#!/bin/bash


### ADDRESS SHOULD BE GET FROM SUPERCHAIN-OPS IN THE FUTURE ###


## ETHEREUM
Security_Council_Safe=0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
Foundation_Upgrade_Safe=0x847B5c174615B1B7fDF770882256e2D3E95b9D92
Foundation_Operation_Safe=0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
Proxy_Admin_Owner_Safe=0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
##############################################################
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
  # Kill the anvil fork at the end
  ps aux | grep anvil | grep -v grep | awk '{print $2}' | xargs kill
}
createFork() {
  # Start a fork
  echo "Starting anvil fork..."
  # check if the port is already open
  if lsof -Pi :8545 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 8545 is already in use, killing previous anvil fork..."
    ps aux | grep anvil | grep -v grep | awk '{print $2}' | xargs kill


  fi
  anvil -f $RPC_URL --fork-block-number 21573136 >> /tmp/anvil.logs & 
  sleep 5
}

NonceDisplay(){
  echo " $1 NONCES STATUS:"
  echo "Foundation Upgrade Safe (FuS) nonce: "$(cast call $Foundation_Upgrade_Safe  "nonce()(uint256)" --rpc-url http://localhost:8545)"."
  echo "Foundation Operation Safe (FoS) nonce: "$(cast call $Foundation_Operation_Safe  "nonce()(uint256)" --rpc-url http://localhost:8545)"."
  echo "Security Council Safe (SC) nonce: "$(cast call $Security_Council_Safe  "nonce()(uint256)" --rpc-url http://localhost:8545)"."
  echo "L1ProxyAdminOwner (L1PAO) nonce: "$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url http://localhost:8545)"."
  echo "==========================================================="
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


source ${task_folders[0]}/.env
echo "RPC: $ETH_RPC_URL"
RPC_URL=$ETH_RPC_URL
unset ETH_RPC_URL
echo "Simulating the following tasks in order:"
for task_folder in "${task_folders[@]}"; do
  echo "  $(realpath "$task_folder")"
done
# Create the anvil Fork 
createFork
# Disable state overrides and execute tasks.
# disable_state_overrides
export SIMULATE_WITHOUT_LEDGER=1
for task_folder in "${task_folders[@]}"; do
  echo -e "\n---- Simulating task $task_folder ----"

  NonceDisplay "(🟧) Before Simulation"
  pushd "$task_folder" >/dev/null || error_exit "Failed to navigate to '$task_folder'."
  # add the RPC_URL to the .env file
  # echo "ETH_RPC_URL=http://localhost:8545" >> "${PWD}/.env" # Replace with the anvil fork URL
  if [[ -f "${task_folder}/NestedSignFromJson.s.sol" ]]; then
    echo "Task type: nested"
   
    approvalhashcouncil=$(just \
      --dotenv-path "${PWD}/.env" \
      --justfile "${root_dir}/nested.just" \
      approvehash_in_anvil council)
   
    approvalhashfoundation=$(just \
      --dotenv-path "${PWD}/.env" \
      --justfile "${root_dir}/nested.just" \
      approvehash_in_anvil foundation)
    
    execution=$(just \
       --dotenv-path "${PWD}/.env" \
       --justfile "${root_dir}/nested.just" \
       execute_in_anvil 0)

    echo $execution

  else
    echo "Task type detected: single"
    simulate=$(just --dotenv-path "${PWD}/.env" --justfile "${root_dir}/single.just" approvehash_in_anvil 0)
    execution=$(just --dotenv-path "${PWD}/.env" --justfile "${root_dir}/single.just" execute_in_anvil 0)
    echo ""
  fi
  sleep 5
  NonceDisplay "(🟩) After Simulation"
  popd >/dev/null || error_exit "Failed to return to previous directory."
done

echo ✅ Success!
