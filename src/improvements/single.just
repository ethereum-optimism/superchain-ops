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


# Simulate sequence execution variables
export ANVIL_LOCALHOST_RPC :="http://localhost:8545"
export PRIVATE_KEY_OWNER := "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PRIVATE_KEY_EXECUTOR :="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export FAKE_SIG :="11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"


# Keystore variables
export keystorePathBase := "~/.foundry/keystores/"

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
    --sig "simulateRun(string)" ${config}

sign hdPath='0' ledger='true':
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  echo "script name: ${SCRIPT_NAME}"
  echo "task path: ${TASK_PATH}"
  echo "script path: ${SCRIPT_PATH}"

  export SIGNING_MODE_IN_PROGRESS=true

  echo "Using script ${script}"
  echo "getting signer address..."
  if {{ledger}}; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    signer_args="--ledger --hd-paths \"m/44'/60'/{{hdPath}}'/0/0\""
  else
    cd ${TASK_PATH}
    signer_private_key=$(just --justfile={{justfile()}} get-keystore-private-key)
    signer=$(cast wallet address --private-key ${signer_private_key})
    signer_args="--private-key ${signer_private_key}"
  fi
  echo "Signing with: ${signer}"

  # Reverts if signer is not an owner on the safe which executes this transaction.
  # forge script TaskManager --rpc-url ${rpcUrl} --sig "requireSignerOnSafe(address,string)" $signer $TASK_PATH

  echo "⏳ Task signing in progress. Some tasks take longer than others..."
  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  $(git rev-parse --show-toplevel)/bin/eip712sign ${signer_args} -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "simulateRun(string)" ${config}

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
    signer_private_key=$(just --justfile={{justfile()}} get-keystore-private-key)
    sender=$(cast wallet address --private-key ${signer_private_key})
    signer_args="--private-key ${signer_private_key}"
  fi
  echo "Executing with sender: ${sender}"

  forge build
  forge script --fork-url ${rpcUrl} ${script} \
    --sig "executeRun(string,bytes)" ${config} ${signatures} \
    --broadcast \
    --sender ${sender} \
    ${signer_args}

sign_and_execute_in_anvil parentSafe:
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  config=${TASK_PATH}/config.toml
  echo "script name: ${SCRIPT_NAME}"
  echo "task path: ${TASK_PATH}"
  echo "script path: ${SCRIPT_PATH}"

  echo "Using script ${script}"
  echo "getting signer address..."
  signer=$(cast wallet address --private-key ${PRIVATE_KEY_EXECUTOR})
  echo "Signing with: ${signer}"
  echo ""

  ownerSafe={{parentSafe}}

  echo "============ OVERRIDE SAFE SETTINGS '${ownerSafe}' ============"
  echo "1. Set the threshold to 1."
  cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000004 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${ANVIL_LOCALHOST_RPC}

  echo "2.set the owner count to 1."
  ## 2. Set the owner count to 1.
  cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000003 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${ANVIL_LOCALHOST_RPC}
  echo "3.Insert the address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 as the sole owner of the safe."
  ## 3. Set the 0xf39 address to the sole signer of the safe.
  # cast keccak 1 || 2 => 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 expected owner mapping: {0x1 -> 0xf39..., 0xf39 -> 0x1}
  cast rpc anvil_setStorageAt ${ownerSafe} 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 0x000000000000000000000000f39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url ${ANVIL_LOCALHOST_RPC}
  ## 4. Set the owner (abi.encode(owner, uint256(2)))-> to sentinel_address (0x1).
  echo "4.Close the mapping of the owners to the sentinel address."
  cast rpc anvil_setStorageAt ${ownerSafe} 0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1  0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${ANVIL_LOCALHOST_RPC}

  echo "the sole Owner of the ${ownerSafe} is: $(cast call ${ownerSafe}  "getOwners()(address[])" --rpc-url http://localhost:8545)"
  echo "================================================"
  # sender=$(cast wallet address --private-key  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  signature=$($(git rev-parse --show-toplevel)/bin/eip712sign --private-key ${PRIVATE_KEY_OWNER:2} -- \
  forge script ${script} \
    --rpc-url ${ANVIL_LOCALHOST_RPC} \
    --sig "simulateRun(string)" ${config})
  signature=$(echo "${signature}" | grep -o "Signature: [0-9a-f]\{130\}" | cut -d' ' -f2)

  forge script ${script} \
    --sig "executeRun(string,bytes)" ${config} ${signature} \
    --broadcast \
    --sender ${signer} \
    --private-key  ${PRIVATE_KEY_EXECUTOR} \
    --rpc-url ${ANVIL_LOCALHOST_RPC}

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
  echo "Signing with the signer: ${sender}" >&2
  if [ -z "${signer_private_key}" ]; then
    echo "Error: Failed to get private key for keystore ${keystorePath}" >&2
    exit 1
  fi
  echo "${signer_private_key}"
