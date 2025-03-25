#!/usr/bin/env bash
set -euo pipefail

# This script uses a Tenderly simulation payload to execute a simulation and retrieve
# the domain and message hashes from its trace. 
# Usage: ./get-tenderly-hashes.sh '{"json":"payload"}'
# Or: ./get-tenderly-hashes.sh --from-link 'https://dashboard.tenderly.co/...'

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

# Check if a payload or link was provided
if [ $# -lt 1 ]; then
  echo "Error: JSON payload or Tenderly link is required"
  echo "Usage: $0 '<json_payload>'"
  echo "   or: $0 --from-link '<tenderly_link>'"
  exit 1
fi

# Process arguments
if [ "$1" = "--from-link" ]; then
  if [ $# -lt 2 ]; then
    echo "Error: Tenderly link is required with --from-link option"
    echo "Usage: $0 --from-link '<tenderly_link>'"
    exit 1
  fi
  # Make sure to quote the URL when passing it to the function
  payload=$(extract_payload_from_link "$2")
  
  # Show a message about how to properly use the command with URLs
  if [[ "$2" =~ ^[\'\"] ]]; then
    echo "Note: When passing URLs with special characters, make sure to quote them:"
    echo "  $0 --from-link 'https://dashboard.tenderly.co/...'"
  fi
else
  payload="$1"
fi

# These are not secrets so that the simulation URL shows up
tenderly_user="${TENDERLY_USER:-oplabs}"
tenderly_project_slug="${TENDERLY_PROJECT_SLUG:-task-simulation}"

# Check for required environment variables
if [ -z "${TENDERLY_ACCESS_TOKEN:-}" ]; then
  echo "Error: TENDERLY_ACCESS_TOKEN environment variable is required" >&2
  exit 1
fi

# Call Tenderly simulation API
echo "Calling Tenderly simulation API..."
response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "X-Access-Key: $TENDERLY_ACCESS_TOKEN" \
  -d "$payload" \
  "https://api.tenderly.co/api/v1/account/$tenderly_user/project/$tenderly_project_slug/simulate")

# Check if the response contains an error
if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
  echo "Payload: $payload"
  echo "Error from Tenderly API: $(echo "$response" | jq -r '.error')" >&2
  exit 1
fi

# Extract the simulation ID from the response
simulation_id=$(echo "$response" | jq -r '.simulation.id')
echo "Simulation ID: $simulation_id"

# Output the Tenderly dashboard URL
echo -e "\nView the simulation in Tenderly dashboard:"
echo "https://dashboard.tenderly.co/$tenderly_user/$tenderly_project_slug/simulator/$simulation_id"

# Retrieve the full simulation details
# echo -e "\nRetrieving full simulation details..."
simulation_details=$(curl -s -X POST -H "X-Access-Key: $TENDERLY_ACCESS_TOKEN" \
  "https://api.tenderly.co/api/v1/account/$tenderly_user/project/$tenderly_project_slug/simulations/$simulation_id")

# Check if there was an error retrieving the simulation details
if echo "$simulation_details" | jq -e '.error' >/dev/null 2>&1; then
  echo -e "Simulation response:" >&2
  echo "$response" | jq 'del(.contracts)' >&2
  echo -e "Error retrieving simulation details:" >&2
  echo "$simulation_details" | jq -r '.' >&2
  echo "$simulation_details" | jq -r '.error' >&2
  exit 1
fi

# Check if the transaction succeeded
# echo -e "\nChecking if the transaction succeeded..."
if echo "$simulation_details" | jq -e '.transaction.status == false' > /dev/null; then
  echo "Error: Transaction failed in Tenderly" >&2
  exit 1
fi

# Extract the call trace from the response
call_trace=$(echo "$simulation_details" | jq -r '.transaction.transaction_info.call_trace')

# Check if there was an error extracting the call trace
if [ "$call_trace" = "null" ]; then
  echo "Error: Could not extract call trace from simulation details" >&2
  exit 1
fi

# Run a recursive jq search for the hashes in the checkSignatures inputs.
hashes=$(echo "$call_trace" | jq -r '.. | objects |
  select(
    has("function_name") and 
    .function_name != null and 
    (.function_name | contains("checkSignatures"))) |
    .decoded_input[] |
      select(.value != null and
      (.value | tostring | contains("0x1901")))
        .value
  ')

# Check if there are any hashes
if [ -z "$hashes" ]; then
  echo "Error: No hashes found in the call trace" >&2
  exit 1
fi

echo -e "\n\n-------- Domain Separator and Message Hashes from Tenderly --------"
# Extract domain separator and message hash from the full hash
full_hash=$(echo "$hashes" | tr -d '\n')
domain_separator="0x${full_hash:6:64}"
message_hash="0x${full_hash:70:64}"

echo "  Domain Separator: $domain_separator"
echo "  Message Hash: $message_hash"
