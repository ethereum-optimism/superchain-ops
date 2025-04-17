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
    --rpc-url ${ANVIL_LOCALHOST_RPC} \
    --sender ${signer} \
    --sig "simulateAsSigner(string,address)" \
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

  echo "⏳ Task signing in progress. Some tasks take longer than others..."
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

approve_in_anvil whichSafe signature:
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")

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

execute hdPath='0':
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "Using script ${script}"
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  echo "⏳ Task execution in progress. Some tasks take longer than others..."
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


approvehash_in_anvil2 whichSafe hdPath='0':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe


  safe=$(bash ${SCRIPT_PATH}/script/get-safe.sh ${TASK_PATH} "{{whichSafe}}")
  echo "safe: $safe"
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  
  sender=$(cast wallet address --private-key ${PRIVATE_KEY_OWNER})
  ownerSafe=${safe}
  echo "============ OVERRIDE SAFES SETTINGS Parent Safe:'${ownerSafe}' & Child Safe: '${safe}' ============"
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
  res_sig=$(eip712sign --private-key ${privateKey}  -- \
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
  echo $(pwd)
  cd ${TASK_PATH}
  just --justfile ${SCRIPT_PATH}/nested.just approve_in_anvil {{whichSafe}} ${signature}


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

## approvehash_in_anvil is a function to generate the nested hash and approve the hash for the given safes (SC, or FND) for later executing during the simulation using the execute_in_anvil function.
# approvehash_in_anvil whichSafe hdPath='0':
#   #!/usr/bin/env bash
#   # set -x
#   ANVIL_LOCALHOST_RPC="http://localhost:8545"
#   bundlePath=${taskPath}/${bundleName}.json
#   script=NestedSignFromJson
#   signer=""
#   echo "Approving hash in Anvil.."

#   if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
#     script="${taskPath}/NestedSignFromJson.s.sol"
#     echo "Running script with assertions"
#   fi
#   echo "Using script ${script}"
#   if [ "{{whichSafe}}" == "foundation" ]; then
#     safe="{{foundationSafe}}"
#     echo "Using foundation safe at ${safe}"
#   fi
#   if [ "{{whichSafe}}" == "council" ]; then
#     safe="{{councilSafe}}"
#     echo "Using council safe at ${safe}"
#   fi
#   if [ "{{whichSafe}}" == "chain-governor" ]; then
#     if [ -z "{{chainGovernorSafe}}" ]; then
#       echo "Error: CHAIN_GOVERNOR_SAFE is not set for chain-governor." >&2
#       exit 1
#     fi
#     safe="{{chainGovernorSafe}}"
#   fi

#   echo "Using script ${script} with nested approvehash_in_anvil."
#   echo "Safe address: ${ownerSafe}"
#   echo "Getting signer address..."

#   if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
#     signer=$(cast wallet address --private-key ${PRIVATE_KEY_OWNER})
#     echo "${PRIVATE_KEY_OWNER}"
#   else
#     signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
#   fi
#   echo "============ OVERRIDE SAFES SETTINGS Parent Safe:'${ownerSafe}' & Child Safe: '${safe}' ============"
#   echo "1. Set the threshold to 1 of the child safe."
#   cast rpc anvil_setStorageAt ${safe} 0x0000000000000000000000000000000000000000000000000000000000000004 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${ANVIL_LOCALHOST_RPC}

#   echo "2. Set the owner count to 1."
#   cast rpc anvil_setStorageAt ${safe} 0x0000000000000000000000000000000000000000000000000000000000000003 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${ANVIL_LOCALHOST_RPC}


#   # cast index address 0x0000000000000000000000000000000000000001 2 => 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 expected owner mapping: {0x1 -> 0xf39..., 0xf39 -> 0x1}
#   echo "3. Insert the address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 as the sole owner of the safe."
#   cast rpc anvil_setStorageAt ${safe} 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 0x000000000000000000000000f39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url ${ANVIL_LOCALHOST_RPC}
  
#   echo "4. Close the mapping of the owners to the sentinel address."
#   # cast index address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 2 => 0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1
#   cast rpc anvil_setStorageAt ${safe} 0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1  0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${ANVIL_LOCALHOST_RPC}
#   echo "The sole Owner of the \"${safe}\" is: $(cast call ${safe}  "getOwners()(address[])" --rpc-url http://localhost:8545)"
#   echo "================================================"
  
#   forge build
#   outputforge=$(forge script ${script} \
#     --rpc-url ${ANVIL_LOCALHOST_RPC} \
#     --private-key {{PRIVATE_KEY_OWNER}} \
#     --sig "signJson(string,address)" \
#     ${bundlePath} \
#     ${safe})

#   tempfile=$(mktemp)
#   echo "tmp file located to:" > $tempfile
#   echo "Outputforge: $outputforge" > $tempfile   
#   ## 1. Generate hash for the SC and FND
#   hash=$(cat $tempfile | grep -A 1 "If submitting onchain, call Safe.approveHash on " | cut -d ':' -f 2 | tr -d '[:space:]')

#   if [[ -z "$hash" ]]; then
#       echo "Hash not found in the file."
#       exit 10
#   else
#       echo "Extracted Hash: $hash"
#   fi

#   ## 2. Approval of this hash in the SC and FND respectively.
#   cast send ${safe} "approveHash(bytes32)" ${hash} --rpc-url ${ANVIL_LOCALHOST_RPC} --private-key {{PRIVATE_KEY_OWNER}} 2>&1 /dev/null 

#   ## 3. Execute the Approval from another private-key `PRIVATE_KEY_EXECUTOR` on the L1PAO. 
#   # This will revert, if there is an error with the nonce here and throw the GS025 error on the logs.
#   forge script ${script} \
#     --rpc-url ${ANVIL_LOCALHOST_RPC} \
#     --broadcast \
#     --private-key {{PRIVATE_KEY_EXECUTOR}} \
#     --sig "approveJson(string,address,bytes)" \
#     ${bundlePath} \
#     ${safe} \
#     ${FAKE_SIG} 2>&1 /dev/null
  
# ## execute_in_anvil is a function to execute hash in anvil dedicated for simulation.
# execute_in_anvil hdPath='0':
#   #!/usr/bin/env bash
#   # set -x
#   bundlePath=${taskPath}/${bundleName}.json
#   script=NestedSignFromJson
#   if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
#     script="${taskPath}/NestedSignFromJson.s.sol"
#     echo "Running script with assertions"
#   fi
#   echo "Using script ${script}"

#   if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
#     signer=$(cast wallet address --private-key ${PRIVATE_KEY_OWNER}) # corresponding to 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 private-key.
#   else
#     signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
#   fi

#   ## 4. Once the L1PAO has the two approvhashes, we execute the transaction permissionlessly.nested.just
#   forge build
#   execution=$(forge script ${script} \
#     --rpc-url ${ANVIL_LOCALHOST_RPC} \
#     --broadcast --private-key {{PRIVATE_KEY_EXECUTOR}} \
#     --sig "runJson(string)" \
#     ${bundlePath} 2>&1)

