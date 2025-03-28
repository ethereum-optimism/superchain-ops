#!/bin/bash
set -euo pipefail

# This script simulates a task both locally and with Tenderly.
# It then verifies the hashes from both simulations against the provided as a parameter.
# task: the path to the task to simulate
# nested_safe_name: the name of the nested safe to simulate as, leave blank for single tasks
# domain_separator: the domain separator to verify against
# message_hash: the message hash to verify against
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
simulate_verify_task() {
    task=$1
    nested_safe_name=$2
    domain_separator=$3
    message_hash=$4
    root_dir=$(git rev-parse --show-toplevel)
    local_output_file="./simulation_output.txt"
    remote_output_file="./remote_output.txt"

    "$root_dir"/src/improvements/script/simulate-task.sh "$task" "$nested_safe_name" | tee "$local_output_file"

    # Extract domain separator and message hash from the simulation output
    domain_separator_local=$(awk '/Domain Hash:/{print $3}' "$local_output_file")
    message_hash_local=$(awk '/Message Hash:/{print $3}' "$local_output_file")

    # Compare the local and provided domain separator and message hash
    if [ "$domain_separator_local" != "$domain_separator" ]; then
        echo -e "\n\n\033[1;31mLocal domain separator mismatch\033[0m\n"
        echo "Validation: $domain_separator"
        echo "Local: $domain_separator_local"
        exit 1
    fi
    if [ "$message_hash_local" != "$message_hash" ]; then
        echo -e "\n\n\033[1;31mLocal message hash mismatch\033[0m\n"
        echo "Validation: $message_hash"
        echo "Local: $message_hash_local"
        exit 1
    fi
    echo -e "\n\n\033[1;32mLocal hashes match\033[0m\n"

    # Extract Tenderly simulation link from output and convert into a JSON payload
    tenderly_link=$(grep -A 1 "Simulation link:" "$local_output_file" | grep -v "Simulation link:" | grep "https://" | tr -d '[:space:]')
    tenderly_payload=$(extract_payload_from_link "$tenderly_link")
    rm "$local_output_file"

    # Exit if the payload is not well formed using jq
    if ! jq -e . > /dev/null 2>&1 <<< "$tenderly_payload"; then
        echo -e "Could not parse Tenderly link into JSON payload"
        exit 1
    fi
    
    # Simulate the task with Tenderly and extract the domain and message hashes
    "$root_dir"/src/improvements/script/get-tenderly-hashes.sh "$tenderly_payload" 2>&1 | tee "$remote_output_file"   

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
}

# Function to extract parameters from a Tenderly simulation link and build a JSON payload
extract_payload_from_link() {
  link="$1"
  
  # Extract parameters from the URL using sed and URL decoding
  network_id=$(echo "$link" | sed -n 's/.*network=\([^&]*\).*/\1/p')
  contract_address=$(echo "$link" | sed -n 's/.*contractAddress=\([^&]*\).*/\1/p')
  from_address=$(echo "$link" | sed -n 's/.*from=\([^&]*\).*/\1/p')
  raw_input=$(echo "$link" | sed -n 's/.*rawFunctionInput=\([^&]*\).*/\1/p')
  
  # Extract state overrides - this is more complex due to URL encoding
  state_overrides=$(echo "$link" | sed -n 's/.*stateOverrides=\([^&]*\).*/\1/p' | sed 's/%5B/[/g' | sed 's/%5D/]/g' | sed 's/%7B/{/g' | sed 's/%7D/}/g' | sed 's/%22/"/g' | sed 's/%3A/:/g' | sed 's/%2C/,/g')
  
  # Build the JSON payload
  payload_json="{\"network_id\":\"$network_id\",\"from\":\"$from_address\",\"to\":\"$contract_address\",\"save\":true,\"input\":\"$raw_input\",\"value\":\"0x0\""
  
  # Add state_objects if state_overrides is not empty
  if [ -n "$state_overrides" ]; then
    # Extract the inner content of the state overrides array
    state_objects=$(echo "$state_overrides" | sed -n 's/^\[\(.*\)\]$/\1/p')
    
    # Convert the state overrides format to the state_objects format expected by the API
    formatted_state_objects="{}"
    
    # If we have valid state objects, format them properly
    if [ -n "$state_objects" ]; then
      # This is a simplified approach - for complex state overrides, we might need a more robust parser
      formatted_state_objects="{\"$contract_address\":{\"storage\":{"

      # Extract key-value pairs from state overrides
      storage_items=$(echo "$state_objects" | grep -o '"key":"[^"]*","value":"[^"]*"' | sed 's/"key":"\([^"]*\)","value":"\([^"]*\)"/"\1":"\2"/g' | paste -sd "," -)
      formatted_state_objects="$formatted_state_objects$storage_items}}}"
    fi
    
    # Add state_objects to payload
    payload_json="${payload_json},\"state_objects\":${formatted_state_objects}"
  fi
  
  payload_json="$payload_json}"
  echo "$payload_json"
}

simulate_verify_task "$1" "$2" "$3" "$4"