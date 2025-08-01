set dotenv-load

# Common variables
export TASK_PATH := invocation_directory()
export SCRIPT_PATH := justfile_directory()

# Get RPC URL and template name
rpc_cmd := SCRIPT_PATH + "/script/get-rpc-url.sh \"" + TASK_PATH + "\""
export rpcUrl := shell(rpc_cmd)
cmd := "yq '.templateName' " + TASK_PATH + "/config.toml"
export SCRIPT_NAME := shell(cmd)
export signatures := env_var_or_default('SIGNATURES', '')

# Anvil simulation variables
export ANVIL_LOCALHOST_RPC :="http://localhost:8545"
export PRIVATE_KEY_OWNER := "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PRIVATE_KEY_EXECUTOR :="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

approve_in_anvil whichSafe signature:
  #!/usr/bin/env bash
  #set -x
  echo "{{whichSafe}}"
  echo "{{signature}}"

  # Get the appropriate safe address based on whichSafe
  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")
  threshold=$(cast call $safe "getThreshold()(uint256)" --rpc-url ${ANVIL_LOCALHOST_RPC})
  # echo "Threshold: $threshold"
  getOwners=$(cast call $safe "getOwners()(address[])" --rpc-url ${ANVIL_LOCALHOST_RPC})
  # echo "Owners: $getOwners"
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  sender=$(cast wallet address --private-key ${PRIVATE_KEY_EXECUTOR})

  forge build
  forge script ${script} \
    --fork-url ${ANVIL_LOCALHOST_RPC} \
    --broadcast \
    --sender ${sender} \
    --sig "approve(string,address,bytes)" \
    --private-key ${PRIVATE_KEY_EXECUTOR} \
    ${config} \
    ${safe} \
    {{signature}}

sign_and_approve_in_anvil whichSafe parentSafe:
  #!/usr/bin/env bash

  # set -x
  export DISABLE_OVERRIDE_NONCE_CHECK=1
  # Disable exit on error temporarily

  # Get the appropriate safe address based on whichSafe
  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")
  echo "safe: $safe"
  if [ -z "$safe" ]; then
    echo "Error: safe is empty"
    exit 1
  fi
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  sender=$(cast wallet address --private-key ${PRIVATE_KEY_OWNER})

  echo "============ OVERRIDE SAFES SETTINGS Parent Safe:'{{parentSafe}}' & Child Safe: '${safe}' ============"
  echo "1. Set the threshold to 1 of the child safe."
  cast rpc anvil_setStorageAt ${safe} 0x0000000000000000000000000000000000000000000000000000000000000004 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${ANVIL_LOCALHOST_RPC}

  echo "2. Set the owner count to 1."
  cast rpc anvil_setStorageAt ${safe} 0x0000000000000000000000000000000000000000000000000000000000000003 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${ANVIL_LOCALHOST_RPC}


  # cast index address 0x0000000000000000000000000000000000000001 2 => 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 expected owner mapping: {0x1 -> 0xf39..., 0xf39 -> 0x1}
  echo "3. Insert the address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 as the sole owner of the safe."
  cast rpc anvil_setStorageAt ${safe} 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 0x000000000000000000000000f39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url ${ANVIL_LOCALHOST_RPC}

  echo "4. Close the mapping of the owners to the sentinel address."
  # cast index address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 2 => 0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1
  cast rpc anvil_setStorageAt ${safe} 0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1  0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${ANVIL_LOCALHOST_RPC}
  echo "The sole Owner of the \"${safe}\" is: $(cast call ${safe}  "getOwners()(address[])" --rpc-url http://localhost:8545)"
  echo "================================================"
  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  # We remove the 2 first characters of the private key ${PRIVATE_KEY_OWNER}
  privateKey=${PRIVATE_KEY_OWNER:2}
  res_sig=$($(git rev-parse --show-toplevel)/bin/eip712sign --private-key ${privateKey}  -- \
  forge script ${script} \
    --rpc-url ${ANVIL_LOCALHOST_RPC} \
    --sig "simulate(string,address)" \
    ${config} \
    "${safe}")
  signature=$(echo "$res_sig" | grep -o 'Signature: [a-fA-F0-9]\{130\}' | cut -d' ' -f2)

  # Check if the signature is not empty
  if [ -n "$signature" ]; then
      echo "Signature found: $signature"
  else
      echo "[ERROR] No signature found extracted from simulate(string,address)"
      exit 1
  fi
  cd ${TASK_PATH}

  # Run the command and capture both stdout and stderr
  approve_res=$(just --justfile ${SCRIPT_PATH}/nested.just approve_in_anvil {{whichSafe}} ${signature} 2>&1)
  if [[ $approve_res == *"not enough signatures"* ]]; then
    echo "Signature is incorrect"
    exit 100
  fi

execute_in_anvil:
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "Using script ${script}"
  sender=$(cast wallet address --private-key ${PRIVATE_KEY_EXECUTOR})

  forge build
  forge script ${script} \
    --fork-url ${ANVIL_LOCALHOST_RPC} \
    --broadcast \
    --sender ${sender} \
    --sig "execute(string,bytes)" \
    --private-key ${PRIVATE_KEY_EXECUTOR} \
    ${config} \
    "0x"
