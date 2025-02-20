#!/bin/bash


LOGFILE="/tmp/sim-sequence.log"
## Nonce Values
MAX_NONCE_ERROR=9999999
FUS_BEFORE=$MAX_NONCE_ERROR
FOS_BEFORE=$MAX_NONCE_ERROR
SC_BEFORE=$MAX_NONCE_ERROR
L1PAO_BEFORE=$MAX_NONCE_ERROR

ANVIL_LOCALHOST_RPC="http://localhost:8545"
## LOG utilies
log_debug() {
    echo "[-] $(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $1" | tee -a "$LOGFILE"
}

# Function to log warning messages
log_warning() {
    echo "[⚠️] $(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" | tee -a "$LOGFILE"
}

# Function to log error messages and exit the script  
log_error() {
    echo -e "\033[0;31m[❌] $(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1\033[0m" | tee -a "$LOGFILE" >&2
}

log_info() {
    echo -e "\033[0;34m[ℹ️] $(date '+%Y-%m-%d %H:%M:%S') [INFO] $1\033[0m" | tee -a "$LOGFILE"
}

# Log the nonce with error and exit the script.
log_nonce_error() {
  echo "est" > /tmp/rce.txt
  echo -e "\033[0;31mFoundation Upgrade Safe (FuS) [$Foundation_Upgrade_Safe] nonce: "$FUS_BEFORE".\033[0m"
  echo -e "\033[0;31mFoundation Operation Safe (FoS) [$Foundation_Operation_Safe] nonce: "$FOS_BEFORE".\033[0m"
  echo -e "\033[0;31mSecurity Council Safe (SC) [$Security_Council_Safe] nonce: "$SC_BEFORE".\033[0m"
  echo -e "\033[0;31mL1ProxyAdminOwner (L1PAO) [$Proxy_Admin_Owner_Safe] nonce: "$L1PAO_BEFORE".\033[0m"
  exit 1

}


#TODO: GET THE ADDRESSES FROM SUPERCHAIN-REGISTRY IN THE FUTURE, since they are the safes addresses this sholdn't change so often so this fine.
## ETHEREUM
Security_Council_Safe=0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
Foundation_Upgrade_Safe=0x847B5c174615B1B7fDF770882256e2D3E95b9D92
Foundation_Operation_Safe=0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
Proxy_Admin_Owner_Safe=0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
DESTROY_ANIVIL_AFTER_EXECUTION=true
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

  # Kill the anvil fork at the end if it was started by this script
  if $DESTROY_ANIVIL_AFTER_EXECUTION; then
    echo "Anvil is still open. To kill it, please use the command below:"
    echo "ps aux | grep anvil | grep -v grep | awk '{print \$3}' | xargs kill"
    #TODO: In the future, we should kill the anvil fork here?
  fi
}
createFork() {
  # Start a fork
  # check if the port is already open
  if lsof -Pi :8545 -sTCP:LISTEN -t >/dev/null ; then
    log_info "Anvil is detected and running on port 8545, we use the current instance of anvil."
    DESTROY_ANIVIL_AFTER_EXECUTION=false
  else  
    log_info "No instance of anvil is detected, starting anvil fork on \"$ANVIL_LOCALHOST_RPC\" by forking $RPC_URL."
    if [[ -n "$block_number" ]]; then
      anvil -f $RPC_URL --fork-block-number $block_number >> /tmp/anvil.logs &
    else
      anvil -f $RPC_URL >> /tmp/anvil.logs &
    fi
    sleep 5
  fi
}

NonceDisplayModified(){
  echo -e "\n$1"
  if [[ $FUS_BEFORE -eq $MAX_NONCE_ERROR || $FOS_BEFORE -eq $MAX_NONCE_ERROR || $SC_BEFORE -eq $MAX_NONCE_ERROR ]]; then
    log_error "Nonce values are not available for one or more safes please investigate." 
    exit 99
  fi
  FUS_AFTER=$(cast call $Foundation_Upgrade_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
  FOS_AFTER=$(cast call $Foundation_Operation_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
  SC_AFTER=$(cast call $Security_Council_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
  L1PAO_AFTER=$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)

  if [[ $FUS_BEFORE -ne $FUS_AFTER ]]; then
    echo -e "\033[0;32mFoundation Upgrade Safe (FuS) [$Foundation_Upgrade_Safe] nonce: "$FUS_AFTER" ("$FUS_BEFORE" -> "$FUS_AFTER").\033[0m" 
  else 
    echo "Foundation Upgrade Safe (FuS) [$Foundation_Upgrade_Safe] nonce: "$(cast call $Foundation_Upgrade_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
  fi 


  if [[ $FOS_BEFORE -ne $FOS_AFTER ]]; then
    echo -e "\033[0;32mFoundation Operation Safe (FoS) [$Foundation_Operation_Safe] nonce: "$FOS_AFTER" ("$FOS_BEFORE" -> "$FOS_AFTER").\033[0m"
  else 
    echo "Foundation Operation Safe (FoS) [$Foundation_Operation_Safe] nonce: "$(cast call $Foundation_Operation_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
  fi
  if [[ $SC_BEFORE -ne $SC_AFTER ]]; then
    echo -e "\033[0;32mSecurity Council Safe (SC) [$Security_Council_Safe] nonce: "$SC_AFTER" ("$SC_BEFORE" -> "$SC_AFTER").\033[0m"
  else 
    echo "Security Council Safe (SC) [$Security_Council_Safe] nonce: "$(cast call $Security_Council_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
  fi 
  if [[ $L1PAO_BEFORE -ne $L1PAO_AFTER ]]; then
    echo -e "\033[0;32mL1ProxyAdminOwner (L1PAO) [$Proxy_Admin_Owner_Safe] nonce: "$L1PAO_AFTER" ("$L1PAO_BEFORE" -> "$L1PAO_AFTER").\033[0m"
  else 
    echo "L1ProxyAdminOwner (L1PAO) [$Proxy_Admin_Owner_Safe] nonce: "$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
  fi

}
 


# Displays the current nonce values for various safes before simulation
# $1: Message to display before showing nonce values
BeforeNonceDisplay(){
  echo -e "\n$1"
  FUS_BEFORE=$(cast call $Foundation_Upgrade_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
  FOS_BEFORE=$(cast call $Foundation_Operation_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
  SC_BEFORE=$(cast call $Security_Council_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
  L1PAO_BEFORE=$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
  echo "Foundation Upgrade Safe (FuS) [$Foundation_Upgrade_Safe] nonce: "$FUS_BEFORE"."
  echo "Foundation Operation Safe (FoS) [$Foundation_Operation_Safe] nonce: "$FOS_BEFORE"."
  echo "Security Council Safe (SC) [$Security_Council_Safe] nonce: "$SC_BEFORE"."
  echo "L1ProxyAdminOwner (L1PAO) [$Proxy_Admin_Owner_Safe] nonce: "$L1PAO_BEFORE"."
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
if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
  echo "Usage: $0 <network> \"<array-of-task-IDs>\" [block_number]" >&2
  exit 1
fi

network="$1"
task_ids="$2"
block_number="${3:-}" # Make block_number optional

# Validate block number if provided
if [[ -n "$block_number" ]]; then
    if ! [[ "$block_number" =~ ^[0-9]+$ ]]; then
        error_exit "Block number must be a valid number, got: $block_number"
    fi
fi

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
RPC_URL=$ETH_RPC_URL
unset ETH_RPC_URL
log_info "Simulating the following tasks in order:"

echo "-------------------------------------------------------"
for task_folder in "${task_folders[@]}"; do
  echo "  $(realpath "$task_folder")"
done
echo "-------------------------------------------------------"
read -p "Are the tasks above are correct? Type 'yes' to proceed with simulation: " confirmation
if [[ "${confirmation}" != "yes" ]]; then
  log_info "Simulation aborted by user."
  exit 0
fi
# Create the anvil Fork 
createFork
# Disable state overrides and execute tasks.
disable_state_overrides
export SIMULATE_WITHOUT_LEDGER=1

for task_folder in "${task_folders[@]}"; do
  execution=""
  echo -e "\n---- Simulating task \"$(basename "$task_folder")\"----"

  pushd "$task_folder" >/dev/null || error_exit "Failed to navigate to '$task_folder'."
  # add the RPC_URL to the .env file
  # echo "ETH_RPC_URL=ANVIL_LOCALHOST_RPC" >> "${PWD}/.env" # Replace with the anvil fork URL
  if [[ -f "${task_folder}/NestedSignFromJson.s.sol" ]]; then
    log_info "Task type: nested" 
    BeforeNonceDisplay "(🟧) Before Simulation Nonce Values (🟧)"
    approvalhashcouncil=$(just \
      --dotenv-path "${PWD}/.env" \
      --justfile "${root_dir}/nested.just" \
      approvehash_in_anvil council)
   
    approvalhashfoundation=$(just \
      --dotenv-path "${PWD}/.env" \
      --justfile "${root_dir}/nested.just" \
      approvehash_in_anvil foundation)

    if [[ $approvalhashcouncil == *"GS025"* ]]; then
      log_error "Execution contains "GS025" meaning the task $task_folder failed during the council approval, please check the nonces below:"
      log_nonce_error 
      exit 99
    fi
    if [[ $approvalhashfoundation == *"GS025"* ]]; then
     log_error "Execution contains "GS025" meaning the task $task_folder failed during the foundation approval, please check the nonces below:"
     log_nonce_error 
     exit 99
    fi
    execution=$(just\
       --dotenv-path "${PWD}/.env" \
       --justfile "${root_dir}/nested.just" \
       execute_in_anvil 0)

  else
    log_info "Task type detected: single"
    BeforeNonceDisplay "(🟧) Before Simulation Nonce Values (🟧)"
    simulate=$(just --dotenv-path "${PWD}/.env" --justfile "${root_dir}/single.just" approvehash_in_anvil 0)
    execution=$(just --dotenv-path "${PWD}/.env" --justfile "${root_dir}/single.just" execute_in_anvil 0)
    if [[ $execution == *"GS025"* ]]; then
     log_error "Execution contains GS025 meaning the task $task_folder failed."
     exit 99
    fi
  fi 

  
  sleep 0.2
  NonceDisplayModified "(🟩) After Simulation Nonce Values (🟩)"
  echo -e "\n---- End of Simulation for task \"$(basename "$task_folder")\" ----"
  popd >/dev/null || error_exit "Failed to return to previous directory."
done

log_info "✅ All tasks has been simulated with success!! ✅"
