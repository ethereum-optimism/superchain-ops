set dotenv-load

# Common variables used across multiple recipes
# Export variables in uppercase for shell script usage
export TASK_PATH := invocation_directory()
export SCRIPT_PATH := justfile_directory()
export JUSTFILE_PATH := justfile()
# Get RPC URL based on task path
rpc_cmd := SCRIPT_PATH + "/script/get-rpc-url.sh \"" + TASK_PATH + "\""
export rpcUrl := shell(rpc_cmd)

# Fetch the template name from the config.toml file
cmd := "yq '.templateName' " + TASK_PATH + "/config.toml"
export SCRIPT_NAME := shell(cmd)
export signatures := env_var_or_default('SIGNATURES', '')
export randomPersonEoa := "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
export forkBlockNumber := env_var_or_default('FORK_BLOCK_NUMBER', '-1')

# Keystore variables
export keystorePathBase := "~/.foundry/keystores/"

# Simulate sequence execution variables
export ANVIL_LOCALHOST_RPC :="http://localhost:8545"
export PRIVATE_KEY_OWNER := "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PRIVATE_KEY_EXECUTOR :="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export FAKE_SIG :="11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"

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

  # Allow simulating from a specific block by setting FORK_BLOCK_NUMBER in the tasks .env file.
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
    --sig "simulateAsSigner(string,address)" \
    ${config} \
    ${safe}

sign whichSafe hdPath='0' ledger='true':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")

  export SIGNING_MODE_IN_PROGRESS=true

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  echo "getting signer address..."
  if {{ledger}}; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    signer_args="--ledger --hd-paths \"m/44'/60'/{{hdPath}}'/0/0\""
  else
    cd ${TASK_PATH}
    signer_private_key=$(just --justfile=${JUSTFILE_PATH} get-keystore-private-key)
    signer=$(cast wallet address --private-key ${signer_private_key})
    signer_args="--private-key ${signer_private_key#0x}"
  fi
  echo "Signing with: ${signer}"

  # Reverts if signer is not an owner on the safe.
  forge script TaskManager --rpc-url ${rpcUrl} --sig "requireSignerOnSafe(address,address)" $signer $safe

  echo "⏳ Task signing in progress. Some tasks take longer than others..."
  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  $(git rev-parse --show-toplevel)/bin/eip712sign ${signer_args} -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signFromChildMultisig(string,address)" \
    ${config} \
    "${safe}"

approve whichSafe hdPath='0' ledger='true':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  if {{ledger}}; then
    sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    signer_args="--ledger --hd-paths \"m/44'/60'/{{hdPath}}'/0/0\""
  else
    cd ${TASK_PATH}
    signer_private_key=$(just --justfile=${JUSTFILE_PATH} get-keystore-private-key)
    sender=$(cast wallet address --private-key ${signer_private_key})
    signer_args="--private-key ${signer_private_key}"
  fi
  echo "Approving with sender: ${sender}"

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --broadcast \
    --sender ${sender} \
    --sig "approveFromChildMultisig(string,address,bytes)" \
    ${signer_args} \
    ${config} \
    ${safe} \
    ${signatures}

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
    --sig "approveFromChildMultisig(string,address,bytes)" \
    --private-key ${PRIVATE_KEY_EXECUTOR} \
    ${config} \
    ${safe} \
    {{signature}}

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

execute hdPath='0' ledger='true':
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "Using script ${script}"
  if {{ledger}}; then
    sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    signer_args="--ledger --hd-paths \"m/44'/60'/{{hdPath}}'/0/0\""
  else
    cd ${TASK_PATH}
    signer_private_key=$(just --justfile=${JUSTFILE_PATH} get-keystore-private-key)
    sender=$(cast wallet address --private-key ${signer_private_key})
    signer_args="--private-key ${signer_private_key}"
  fi
  echo "Executing with sender: ${sender}"

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --broadcast \
    --sender ${sender} \
    --sig "executeRun(string,bytes)" \
    ${signer_args} \
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
    --sig "signFromChildMultisig(string,address)" \
    ${config} \
    "${safe}")
  signature=$(echo "$res_sig" | grep -o 'Signature: [a-fA-F0-9]\{130\}' | cut -d' ' -f2)

  # Check if the signature is not empty
  if [ -n "$signature" ]; then
      echo "Signature found: $signature"
  else
      echo "[ERROR] No signature found extracted from signFromChildMultisig(string,address)"
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
    --sig "executeRun(string,bytes)" \
    --private-key ${PRIVATE_KEY_EXECUTOR} \
    ${config} \
    "0x"


# Helper function to handle keystore selection and private key extraction
get-keystore-private-key:
  #!/usr/bin/env bash
  echo "Enter your foundry keystore path (e.g. ~/.foundry/keystores/sep-test-private-key):" >&2
  keystorePath=$keystorePathBase$(cd ~/.foundry/keystores/ && fzf --header="Searching your keystore in $PWD" --prompt="Keystore for signing:")
  cd ${taskPath}
  echo "Keystore path: ${keystorePath}" >&2
  # Expand the home directory in the path
  keystorePath=$(echo ${keystorePath} | sed "s|^~|$HOME|")
  signer_private_key=$(cast wallet pk --keystore ${keystorePath})
  sender=$(cast wallet address --private-key ${signer_private_key})
  if [ -z "${signer_private_key}" ]; then
    echo "Error: Failed to get private key for keystore ${keystorePath}" >&2
    exit 1
  fi
  echo "${signer_private_key}"