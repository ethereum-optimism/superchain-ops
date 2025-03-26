#!/bin/bash
set -euo pipefail

# This script simulates a task both locally and with Tenderly.
# task: the path to the task to simulate
# nested_safe_name: the name of the nested safe to simulate as, leave blank for single tasks
simulate_tenderly() {
    task=$1
    nested_safe_name=$2

    root_dir=$(git rev-parse --show-toplevel)
    
    local_output_file="./simulation_output.txt"
    "$root_dir"/src/improvements/script/simulate-task.sh "$task" "$nested_safe_name" | tee "$local_output_file"

    # Extract Tenderly simulation link from output into a variable
    tenderly_link=$(grep -A 1 "Simulation link:" "$local_output_file" | grep -v "Simulation link:" | grep "https://" | tr -d '[:space:]')

    # If the links is too long, the raw input will be in its own line. In that case, we append the raw input data back to the tenderly link. We will extract the data just now anyway.
    if [[ "$tenderly_link" != *"rawFunctionInput"* ]]; then
        rawFunctionInput=$(grep -A 1 "Insert the following hex into the 'Raw input data' field:" "$local_output_file" | grep -v "Insert the following hex into the 'Raw input data' field:" | tr -d '[:space:]')
        tenderly_link="$tenderly_link&rawFunctionInput=$rawFunctionInput"
    fi
    rm "$local_output_file"

    # Convert the link to a JSON payload
    payload=$(extract_payload_from_link "$tenderly_link")
    
    if [ -n "$payload" ]; then
        # Simulate the task with Tenderly
        "$root_dir"/src/improvements/script/get-tenderly-hashes.sh "$payload"
    else
        echo -e "\n\n\033[1;31mSimulation link not found in console output\033[0m\n"
        exit 1
    fi
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

simulate_tenderly "$1" "${2:-""}"