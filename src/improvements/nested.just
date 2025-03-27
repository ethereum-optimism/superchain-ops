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
export randomPersonEoa := "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
export forkBlockNumber := env_var_or_default('FORK_BLOCK_NUMBER', '-1')

simulate whichSafe hdPath='0':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")

  echo "RPC URL: ${rpcUrl}"

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "Using script ${script}"
  echo "getting signer address for {{whichSafe}}..."
  signer=$(cast call ${safe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)

  echo "safe: $safe"
  echo "Simulating call to {{whichSafe}} at ${safe}"
  if [ -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    echo "Simulating with ledger account: ${signer}"
  else
      echo "Simulating without ledger using the first owner account: ${signer}"
  fi
  echo ""

  # Allow simulating from a specific block by setting FORK_BLOCK_NUMBER in the task's .env file.
  # If not set (or set to -1), default to using the latest block.
  if [ "${forkBlockNumber}" = "-1" ]; then
    fork_block_arg=""
  else
    echo "Using fork block number from env: ${forkBlockNumber}"
    fork_block_arg="--fork-block-number ${forkBlockNumber}"
  fi

  forge build
  forge script ${script} \
    ${fork_block_arg} \
    --rpc-url ${rpcUrl} \
    --sender ${signer} \
    --sig "signFromChildMultisig(string,address)" \
    ${config} \
    ${safe}

sign whichSafe hdPath='0':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")


  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""

  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signFromChildMultisig(string,address)" \
    ${config} \
    "${safe}"

approve whichSafe hdPath='0':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "approveFromChildMultisig(string,address,bytes)" \
    ${config} \
    ${safe} \
    ${signatures}

simulate-approve whichSafe hdPath='0':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    sender=$(cast call ${safe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)
  else
    sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --sender ${sender} \
    --sig "approveFromChildMultisig(string,address,bytes)" \
    ${config} \
    ${safe} \
    ${signatures}

execute hdPath='0':
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "Using script ${script}"
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "executeRun(string,bytes)" \
    ${config} \
    "0x"

simulated-run hdPath='0':
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "Using script ${script}"

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --sender ${randomPersonEoa} \
    --sig "executeRun(string,bytes)" \
    ${config} \
    "0x"
