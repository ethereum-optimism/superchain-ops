set dotenv-load

# Common variables used across multiple recipes
# Export variables in uppercase for shell script usage
export TASK_PATH := invocation_directory()
export SCRIPT_PATH := justfile_directory()

# Get RPC URL based on task path
rpc_cmd := SCRIPT_PATH + "/script/get-rpc-url.sh \"" + TASK_PATH + "\""
export rpcUrl := shell(rpc_cmd)

# Fetch the template name from the config.toml file
cmd := "yq '.templateName' " + TASK_PATH + "/config.toml"
export SCRIPT_NAME := shell(cmd)
export signatures := env_var_or_default('SIGNATURES', '')

# Simulate a task
# whichSafe is the safe name to simulate, only needed if verification is enabled
# hdPath is the derivation path for the safe
# verify is optional and defaults to "verify-local". Other values are "verify-all", "verify-tenderly" and "skip-verify".
simulate whichSafe='unspecified' hdPath='0' verify='verify-local':
  #!/usr/bin/env bash
  set -euo pipefail
  echo "RPC URL: ${rpcUrl}"
  echo "Simulating call to {{whichSafe}}"
  
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  echo "Using script ${script}"
  echo ""
  

  # We use a file to pass the output to make sure any errors are printed to the console.
  local_output_file="./simulation_output.txt"

  forge build
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "simulateRun(string)" ${config} | tee "$local_output_file"


  # Scrape the Tenderly payload from the output file into a variable
  tenderly_payload=$(awk '/Simulation payload:/{flag=1;next}/\}\}\}\}$/{print;flag=0}flag' "$local_output_file")
  rm "$local_output_file"

  if [ "{{verify}}" = "verify-local" ] || [ "{{verify}}" = "verify-all" ]; then
    ${SCRIPT_PATH}/script/verify-hashes-local.sh "${TASK_PATH}" "{{whichSafe}}" "${tenderly_payload}"
  fi
  if [ "{{verify}}" = "verify-tenderly" ] || [ "{{verify}}" = "verify-all" ]; then
    ${SCRIPT_PATH}/script/verify-hashes-tenderly.sh "${TASK_PATH}" "{{whichSafe}}" "${tenderly_payload}"
  fi
  if [ "{{verify}}" = "skip-verify" ]; then
    echo "Skipping verification"
  fi

sign hdPath='0':
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  echo "script name: ${SCRIPT_NAME}"
  echo "task path: ${TASK_PATH}"
  echo "script path: ${SCRIPT_PATH}"

  echo "Using script ${script}"
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""

  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "simulateRun(string)" ${config}

execute hdPath='0':
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  
  echo "Using script ${script}"
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script --fork-url ${rpcUrl} ${script} \
    --sig "executeRun(string,bytes)" ${config} ${signatures} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" --broadcast \
    --sender ${sender}
