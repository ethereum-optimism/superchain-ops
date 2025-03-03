#!/usr/bin/env bash
set -euo pipefail

# This script uses a Tenderly simulation payload as imput to execute a simulation on and retrieve
# the domain and message hashes from its trace. 
# Usage: ./get-tenderly-trace.sh payload.json

# Check if a payload file was provided
if [ $# -lt 1 ]; then
  echo "Error: Payload file is required"
  echo "Usage: $0 <payload_file>"
  exit 1
fi

PAYLOAD_FILE="$1"

# Check if the payload file exists
if [ ! -f "$PAYLOAD_FILE" ]; then
  echo "Error: Payload file not found: $PAYLOAD_FILE"
  exit 1
fi

# Check for required environment variables
if [ -z "${TENDERLY_ACCESS_TOKEN:-}" ]; then
  echo "Error: TENDERLY_ACCESS_TOKEN environment variable is required"
  exit 1
fi

if [ -z "${TENDERLY_USER:-}" ]; then
  echo "Error: TENDERLY_USER environment variable is required"
  exit 1
fi

if [ -z "${TENDERLY_PROJECT_SLUG:-}" ]; then
  echo "Error: TENDERLY_PROJECT_SLUG environment variable is required"
  exit 1
fi

# Read the payload from file
PAYLOAD=$(cat "$PAYLOAD_FILE")

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

# Output the Tenderly dashboard URL
echo "View the simulation in Tenderly dashboard:"
echo "https://dashboard.tenderly.co/$TENDERLY_USER/$TENDERLY_PROJECT_SLUG/simulator/$SIMULATION_ID"

# Retrieve the full simulation details
# echo "Retrieving full simulation details..."
SIMULATION_DETAILS=$(curl -s -X POST -H "X-Access-Key: $TENDERLY_ACCESS_TOKEN" \
  "https://api.tenderly.co/api/v1/account/$TENDERLY_USER/project/$TENDERLY_PROJECT_SLUG/simulations/$SIMULATION_ID")

# Check if there was an error retrieving the simulation details
if echo "$SIMULATION_DETAILS" | jq -e '.error' >/dev/null 2>&1; then
  echo "Error retrieving simulation details: $(echo "$SIMULATION_DETAILS" | jq -r '.error')" >&2
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

echo ""
echo ""
echo "------------------ Domain and Message Hashes ------------------"
echo "$HASHES"
