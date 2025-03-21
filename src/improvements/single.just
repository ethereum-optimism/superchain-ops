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

simulate hdPath='0':
  #!/usr/bin/env bash

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "RPC URL: ${rpcUrl}"

  echo "Using script ${script}"
  echo ""

  export GEN_VERIFY_INPUT=true

  current_dir=$(pwd)
  # Derive a filepath for the verify input. e.g if the task is in src/improvements/tasks/example/eth/000-gas-config-template.sol
  # then the verify input will be in current_dir/op-verify-inputs/eth/000-gas-config-template-input.json in the current directory
  op_verify_input_filepath="${current_dir}/op-verify-inputs/$(basename "$(dirname "${TASK_PATH}")")/${TASK_PATH##*/}-input.json"
  # Create the directory for the verify input if it does not exist
  mkdir -p "$(dirname "$op_verify_input_filepath")"
  echo "Created op-verify-inputs file: ${op_verify_input_filepath}"
  export OP_VERIFY_INPUT_FILEPATH=${op_verify_input_filepath}

  forge build
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "simulateRun(string)" ${config}

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
