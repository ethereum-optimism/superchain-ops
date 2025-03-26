#!/usr/bin/env bash
set -euo pipefail

# This script uses a Tenderly simulation payload to execute a simulation and retrieve
# the domain and message hashes from its trace. 
# Usage: ./get-tenderly-hashes.sh '{"json":"payload"}'

# Check that the payload was provided
if [ $# -ne 1 ]; then
  echo "Error: JSON payload is required"
  echo "Usage: $0 '<json_payload>'"
  exit 1
fi

# Use jq to verify the JSON is well-formed
if ! jq -e . >/dev/null 2>&1 <<< "$1"; then
  echo "Error: Invalid JSON payload"
  exit 1
fi

payload="$1"

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
