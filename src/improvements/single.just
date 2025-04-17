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
export forkBlockNumber := env_var_or_default('FORK_BLOCK_NUMBER', '-1')
# The 'signerAddress' will be the 'from' field in the Tenderly simulation. 
# Default signer: address(uint160(uint256(keccak256("foundry default caller"))))
export signerAddress := env_var_or_default('SIGNER_ADDRESS', '0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38')

simulate hdPath='0':
  #!/usr/bin/env bash

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "RPC URL: ${rpcUrl}"
  echo "Using script ${script}"

  echo "Setting signer address..."
  if [ -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    echo "Simulating with ledger account: ${signer}"
  else 
    signer="{{signerAddress}}"
    echo "Using 'signerAddress' as signer: ${signer}"
  fi

  # Allow simulating from a specific block by setting FORK_BLOCK_NUMBER in the task's .env file.
  # If not set (or set to -1), default to using the latest block.
  if [ "${forkBlockNumber}" = "-1" ]; then
    fork_block_arg=""
  else
    echo "Using fork block number from env: ${forkBlockNumber}"
    fork_block_arg="--fork-block-number ${forkBlockNumber}"
  fi

  echo "⏳ Task simulation in progress. Some tasks take longer than others..."
  forge build
  forge script ${script} \
    ${fork_block_arg} \
    --rpc-url ${rpcUrl} \
    --sender ${signer} \
    --sig "simulateRun(string)" ${config} -vvvv

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

  echo "⏳ Task signing in progress. Some tasks take longer than others..."
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

  echo "⏳ Task execution in progress. Some tasks take longer than others..."
  forge build
  forge script --fork-url ${rpcUrl} ${script} \
    --sig "executeRun(string,bytes)" ${config} ${signatures} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" --broadcast \
    --sender ${sender}
