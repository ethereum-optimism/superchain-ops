#!/usr/bin/env bash
set -euo pipefail

# This script uses a Tenderly simulation payload to execute a simulation and retrieve
# the domain and message hashes from its trace. 
# Usage: ./get-tenderly-trace.sh '{"json":"payload"}'

# Check if a payload was provided
if [ $# -lt 1 ]; then
  echo "Error: JSON payload is required"
  echo "Usage: $0 '<json_payload>'"
  exit 1
fi

PAYLOAD="$1"

# These are not secrets so that the simulation URL shows up
TENDERLY_USER="${TENDERLY_USER:-oplabs}"
TENDERLY_PROJECT_SLUG="${TENDERLY_PROJECT_SLUG:-task-simulation}"

# Check for required environment variables
if [ -z "${TENDERLY_ACCESS_TOKEN:-}" ]; then
  echo "Error: TENDERLY_ACCESS_TOKEN environment variable is required" >&2
  exit 1
fi

# Call Tenderly simulation API
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "X-Access-Key: $TENDERLY_ACCESS_TOKEN" \
  -d "$PAYLOAD" \
  "https://api.tenderly.co/api/v1/account/$TENDERLY_USER/project/$TENDERLY_PROJECT_SLUG/simulate")

# Check if the response contains an error
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
  echo "Error from Tenderly API: $(echo "$RESPONSE" | jq -r '.error')" >&2
  exit 1
fi

# Extract the simulation ID from the response
SIMULATION_ID=$(echo "$RESPONSE" | jq -r '.simulation.id')

# Retrieve the full simulation details
# echo "Retrieving full simulation details..."
SIMULATION_DETAILS=$(curl -s -X POST -H "X-Access-Key: $TENDERLY_ACCESS_TOKEN" \
  "https://api.tenderly.co/api/v1/account/$TENDERLY_USER/project/$TENDERLY_PROJECT_SLUG/simulations/$SIMULATION_ID")

# Check if there was an error retrieving the simulation details
if echo "$SIMULATION_DETAILS" | jq -e '.error' >/dev/null 2>&1; then
  echo -e "\n\nSimulation response:" >&2
  echo "$RESPONSE" | jq 'del(.contracts)' >&2
  echo -e "\n\nError retrieving simulation details:" >&2
  echo "$SIMULATION_DETAILS" | jq -r '.' >&2
  echo "$SIMULATION_DETAILS" | jq -r '.error' >&2
  exit 1
fi

# Extract the call trace from the response
CALL_TRACE=$(echo "$SIMULATION_DETAILS" | jq -r '.transaction.transaction_info.call_trace')

# Check if there was an error extracting the call trace
if [ "$CALL_TRACE" = "null" ]; then
  echo "Error: Could not extract call trace from simulation details" >&2
  exit 1
fi

# Run a recursive jq search for the hashes in the checkSignatures inputs.
HASHES=$(echo "$CALL_TRACE" | jq -r '.. | objects |
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
if [ -z "$HASHES" ]; then
  echo "Error: No hashes found in the call trace" >&2
  exit 1
fi

echo -e "\n\n-------- Domain Separator and Message Hashes from Tenderly --------"
# Extract domain separator and message hash from the full hash
FULL_HASH=$(echo "$HASHES" | tr -d '\n')
DOMAIN_SEPARATOR="0x${FULL_HASH:6:64}"
MESSAGE_HASH="0x${FULL_HASH:70:64}"

echo "  Domain Separator: $DOMAIN_SEPARATOR"
echo "  Message Hash: $MESSAGE_HASH"

# Output the Tenderly dashboard URL
echo -e "\nView the simulation in Tenderly dashboard:"
echo "https://dashboard.tenderly.co/$TENDERLY_USER/$TENDERLY_PROJECT_SLUG/simulator/$SIMULATION_ID"
