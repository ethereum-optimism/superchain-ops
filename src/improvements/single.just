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

# Simulate sequence execution variables
export ANVIL_LOCALHOST_RPC :="http://localhost:8545"
export PRIVATE_KEY_OWNER := "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PRIVATE_KEY_EXECUTOR :="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export FAKE_SIG :="11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"

# Keystore variables
export keystorePathBase := "~/.foundry/keystores/"

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
    --sig "simulate(string)" ${config})
  signature=$(echo "${signature}" | grep -o "Signature: [0-9a-f]\{130\}" | cut -d' ' -f2)

  forge script ${script} \
    --sig "execute(string,bytes)" ${config} ${signature} \
    --broadcast \
    --sender ${signer} \
    --private-key  ${PRIVATE_KEY_EXECUTOR} \
    --rpc-url ${ANVIL_LOCALHOST_RPC}
