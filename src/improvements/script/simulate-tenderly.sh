#!/bin/bash
set -euo pipefail

# This script simulates a task both locally and with Tenderly.
# If provided with a domain separator and message hash, it will verify them against both simulations.
#
# task: the path to the task to simulate
# nested_safe_name: the name of the nested safe to simulate as, use "single" for single tasks
# domain_separator: (optional) the domain separator to verify against
# message_hash: (optional) the message hash to verify against
#
# Parses these strings from the local simulation output:
# Domain Separator: <hash>
# Message Hash: <hash>
# Simulation link: <link>
#
# Parses these strings from get-tenderly-hashes.sh:
# Domain Separator: <hash>
# Message Hash: <hash>
# Simulation link: <link>
simulate_tenderly() {
    task=$1
    nested_safe_name=$2
    domain_separator=$3
    message_hash=$4
    root_dir=$(git rev-parse --show-toplevel)
    local_output_file="./simulation_output.txt"
    remote_output_file="./remote_output.txt"

    "$root_dir"/src/improvements/script/simulate-task.sh "$task" "$nested_safe_name" | tee "$local_output_file"

    # If a domain separator and message hash are provided, verify them against the local simulation
    if [ -n "$domain_separator" ] && [ -n "$message_hash" ]; then
        # Extract domain separator and message hash from the simulation output
        domain_separator_local=$(awk '/Domain Hash:/{print $3}' "$local_output_file")
        message_hash_local=$(awk '/Message Hash:/{print $3}' "$local_output_file")

        # Compare the local and provided domain separator and message hash
        if [ "$domain_separator_local" != "$domain_separator" ]; then
            echo -e "\n\n\033[1;31mLocal domain separator mismatch\033[0m\n"
            echo "Validation: $domain_separator"
            echo "Local: $domain_separator_local"
            rm "$local_output_file"
            exit 1
        fi
        if [ "$message_hash_local" != "$message_hash" ]; then
            echo -e "\n\n\033[1;31mLocal message hash mismatch\033[0m\n"
            echo "Validation: $message_hash"
            echo "Local: $message_hash_local"
            rm "$local_output_file"
            exit 1
        fi
        echo -e "\n\n\033[1;32mLocal hashes match\033[0m\n"
    fi

    # Extract Tenderly simulation link from output and convert into a JSON payload
    tenderly_link=$(grep -A 1 "Simulation link:" "$local_output_file" | grep "https://" | tr -d '[:space:]"')
    
    # If the link is too long, the raw input will be in its own line. In that case, we append the raw input data back to the tenderly link. We will extract the data just now anyway.
    if [[ "$tenderly_link" != *"rawFunctionInput"* ]]; then
        rawFunctionInput=$(grep -A 1 "Insert the following hex into the 'Raw input data' field:" "$local_output_file" | grep -v "Insert the following hex into the 'Raw input data' field:" | tr -d '[:space:]')
        tenderly_link="$tenderly_link&rawFunctionInput=$rawFunctionInput"
    fi
    rm "$local_output_file"

    tenderly_payload=$(extract_payload_from_link "$tenderly_link")

    # Exit if the payload is not well formed using jq
    if ! jq -e '.' > /dev/null 2>&1 <<< "$tenderly_payload"; then
        echo -e "Could not parse Tenderly link into JSON payload"
        exit 1
    fi

    # Simulate the task with Tenderly and extract the domain and message hashes
    "$root_dir"/src/improvements/script/get-tenderly-hashes.sh "$tenderly_payload" 2>&1 | tee "$remote_output_file"   

    # If a domain separator and message hash are provided, verify them against the Tenderly simulation
    if [ -n "$domain_separator" ] && [ -n "$message_hash" ]; then
        # Extract the domain and message hashes from the remote output
        domain_separator_tenderly=$(awk '/Domain Separator:/{print $3}' "$remote_output_file")
        message_hash_tenderly=$(awk '/Message Hash:/{print $3}' "$remote_output_file")
        rm "$remote_output_file"

            # Compare the tenderly hashes with the provided hashes
            if [ "$domain_separator_tenderly" != "$domain_separator" ]; then
                echo -e "\n\n\033[1;31mTenderly domain separator mismatch\033[0m\n"
                echo "Validation: $domain_separator"
                echo "Tenderly: $domain_separator_tenderly"
                exit 1
            fi
            if [ "$message_hash_tenderly" != "$message_hash" ]; then
                echo -e "\n\n\033[1;31mTenderly message hash mismatch\033[0m\n"
                echo "Validation: $message_hash"
                echo "Tenderly: $message_hash_tenderly"
                exit 1
            fi
        echo -e "\n\n\033[1;32mTenderly hashes match\033[0m\n"
    fi
}

# Function to extract parameters from a Tenderly simulation link and build a JSON payload
extract_payload_from_link() {
  link="$1"
  
  # Extract parameters from the URL using sed and URL decoding
  network_id=$(echo "$link" | sed -n 's/.*network=\([^&]*\).*/\1/p')
  contract_address=$(echo "$link" | sed -n 's/.*contractAddress=\([^&]*\).*/\1/p')
  from_address=$(echo "$link" | sed -n 's/.*from=\([^&]*\).*/\1/p')
  gas=$(echo "$link" | sed -n 's/.*gas=\([^&]*\).*/\1/p')
  block_number=$(echo "$link" | sed -n 's/.*block=\([^&]*\).*/\1/p')
  raw_input=$(echo "$link" | sed -n 's/.*rawFunctionInput=\([^&]*\).*/\1/p')

  # Extract state overrides - this is more complex due to URL encoding
  state_overrides=$(echo "$link" | sed -n 's/.*stateOverrides=\([^&]*\).*/\1/p' | sed 's/%5B/[/g' | sed 's/%5D/]/g' | sed 's/%7B/{/g' | sed 's/%7D/}/g' | sed 's/%22/"/g' | sed 's/%3A/:/g' | sed 's/%2C/,/g')

  # Build the JSON payload
  payload_json="{"
  payload_json="$payload_json\"network_id\":\"$network_id\","
  payload_json="$payload_json\"from\":\"$from_address\","
  payload_json="$payload_json\"to\":\"$contract_address\","
  if [ -n "$gas" ]; then
    payload_json="$payload_json\"gas\":$gas,"
  fi
  if [ -n "$block_number" ]; then
    payload_json="$payload_json\"blockNumber\":$block_number,"
  fi
  payload_json="$payload_json\"save\":true,"
  payload_json="$payload_json\"input\":\"$raw_input\","
  payload_json="$payload_json\"value\":\"0x0\","

  # Add state_objects if state_overrides is not empty
  if [ -n "$state_overrides" ]; then
    # Initialize state_objects as an empty JSON object
    state_objects=""
    first_item=true

    # Split in lines by contractAddress using sed and discard the first line
    contracts=$(echo "$state_overrides" | sed 's/contractAddress:/\ncontractAddress:/g' | tail -n +2)

    # There should be contract addresses in the state_overrides, otherwise we should fail
    if [ -z "$contracts" ]; then
      echo -e "\n\n\033[1;31mNo contract addresses found in state_overrides\033[0m\n"
      exit 1
    fi

    # Process each contract
    comma=""
    while read -r contract; do
      # Extract storage items for this address
      storage_items=$(echo "$contract" | grep -o 'key:[^,]*,value:[^}]*' | sed 's/key:\([^,]*\),value:\([^}]*\)/"\1":"\2"/g' | paste -sd "," -)

      # There should be storage items for this address, otherwise we should fail
      if [ -z "$storage_items" ]; then
        echo -e "\n\n\033[1;31mNo storage items found for contract address $addr\033[0m\n"
        exit 1
      fi

      # Add this address and its storage to the formatted object
      addr=$(echo "$contract" | grep -o 'contractAddress:[^,]*' | sed 's/contractAddress://')


      state_objects="$state_objects$comma\"$addr\":{\"storage\":{$storage_items}}"

      # Start adding commas before addresses after the first one
      if [ "$first_item" = true ]; then
        comma=","
      fi
    done <<< "$contracts"

    # Add state_objects to payload
    payload_json="${payload_json}\"state_objects\":{${state_objects}}"
  fi
  
  payload_json="$payload_json}"
  echo "$payload_json"
}

simulate_tenderly "$1" "$2" "${3:-}" "${4:-}"