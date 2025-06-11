set dotenv-load

export rpcUrl := env_var_or_default('ETH_RPC_URL', 'https://ethereum.publicnode.com')
export signatures := env_var_or_default('SIGNATURES', '')
export bundleName := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()

# Keystore variables
export keystorePathBase := "~/.foundry/keystores/"

# Accounts
export councilSafe := env_var("COUNCIL_SAFE")
export foundationSafe := env_var("FOUNDATION_SAFE")
export ownerSafe := env_var('OWNER_SAFE')
export chainGovernorSafe := env_var_or_default('CHAIN_GOVERNOR_SAFE', '')
export randomPersonEoa := "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"

# These are two of the anvil default private keys, they are publicly known
export PRIVATE_KEY_OWNER := "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PRIVATE_KEY_EXECUTOR :="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export ANVIL_LOCALHOST_RPC :="http://localhost:8545"
export FAKE_SIG :="11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"

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
  if [ -z "${signer_private_key}" ]; then
    echo "Error: Failed to get private key for keystore ${keystorePath}" >&2
    exit 1
  fi
  echo "${signer_private_key}"

simulate whichSafe hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  echo "getting signer address for {{whichSafe}}..."

  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
  fi
  if [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "{{chainGovernorSafe}}" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is not set for chain-governor." >&2
      exit 1
    fi
    safe="{{chainGovernorSafe}}"
  fi
  signer=$(cast call ${safe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)

  root_dir=$(git rev-parse --show-toplevel)
  if [ "${FOUNDRY_PROFILE}" == "ci" ]; then
    if [[ "${rpcUrl}" == *"sep"* ]]; then
      ETH_RPC_URL=$(yq eval ".profile.ci.rpc_endpoints.sepolia" "${root_dir}/foundry.toml")
    else
      ETH_RPC_URL=$(yq eval ".profile.ci.rpc_endpoints.mainnet" "${root_dir}/foundry.toml")
    fi
    export ETH_RPC_URL
  fi

  echo "safe: $safe"
  echo "Simulating call to {{whichSafe}} at ${safe}"
  if [ -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    echo "Simulating with ledger account: ${signer}"
  else
      echo "Simulating without ledger using the first owner account: ${signer}"
  fi
  echo ""

  forge build
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sender ${signer} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    "${safe}"

sign whichSafe hdPath='0' ledger='true':
  #!/usr/bin/env bash
  set -x
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
    echo "Using council safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "{{chainGovernorSafe}}" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is not set for chain-governor." >&2
      exit 1
    fi
    safe="{{chainGovernorSafe}}"
  fi
  echo "getting signer address..."
  
  if {{ledger}}; then
    hdpaths="m/44'/60'/{{hdPath}}'/0/0"
    signer=$(cast wallet address --ledger --mnemonic-derivation-path $hdpaths)
    signer_args="--ledger --hd-paths $hdpaths"
  else
    signer_private_key=$(just --justfile={{justfile()}} get-keystore-private-key)
    signer=$(cast wallet address --private-key ${signer_private_key})
    signer_args="--private-key ${signer_private_key#0x}"
  fi
  echo "Signing with: ${signer}"

  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  $(git rev-parse --show-toplevel)/bin/eip712sign ${signer_args} -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    "${safe}"

## approvehash_in_anvil is a function to generate the nested hash and approve the hash for the given safes (SC, or FND) for later executing during the simulation using the execute_in_anvil function.
approvehash_in_anvil whichSafe hdPath='0':
  #!/usr/bin/env bash
  # set -x
  ANVIL_LOCALHOST_RPC="http://localhost:8545"
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  signer=""
  echo "Approving hash in Anvil.."

  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
    echo "Using council safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "{{chainGovernorSafe}}" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is not set for chain-governor." >&2
      exit 1
    fi
    safe="{{chainGovernorSafe}}"
  fi

  echo "Using script ${script} with nested approvehash_in_anvil."
  echo "Safe address: ${ownerSafe}"
  echo "Getting signer address..."

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --private-key ${PRIVATE_KEY_OWNER})
    echo "${PRIVATE_KEY_OWNER}"
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi
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
  outputforge=$(forge script ${script} \
    --rpc-url ${ANVIL_LOCALHOST_RPC} \
    --private-key {{PRIVATE_KEY_OWNER}} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    ${safe})
  tempfile=$(mktemp)
  echo "tmp file located to:" > $tempfile
  echo "Outputforge: $outputforge" > $tempfile   
  ## 1. Generate hash for the SC and FND
  hash=$(cat $tempfile | grep -A 1 "If submitting onchain, call Safe.approveHash on " | cut -d ':' -f 2 | tr -d '[:space:]')

  if [[ -z "$hash" ]]; then
      echo "Hash not found in the file."
      exit 10
  else
      echo "Extracted Hash: $hash"
  fi

  ## 2. Approval of this hash in the SC and FND respectively.
  cast send ${safe} "approveHash(bytes32)" ${hash} --rpc-url ${ANVIL_LOCALHOST_RPC} --private-key {{PRIVATE_KEY_OWNER}} 2>&1 /dev/null 

  ## 3. Execute the Approval from another private-key `PRIVATE_KEY_EXECUTOR` on the L1PAO. 
  # This will revert, if there is an error with the nonce here and throw the GS025 error on the logs.
  forge script ${script} \
    --rpc-url ${ANVIL_LOCALHOST_RPC} \
    --broadcast \
    --private-key {{PRIVATE_KEY_EXECUTOR}} \
    --sig "approveJson(string,address,bytes)" \
    ${bundlePath} \
    ${safe} \
    ${FAKE_SIG} 2>&1 /dev/null
  
## execute_in_anvil is a function to execute hash in anvil dedicated for simulation.
execute_in_anvil hdPath='0':
  #!/usr/bin/env bash
  # set -x
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --private-key ${PRIVATE_KEY_OWNER}) # corresponding to 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 private-key.
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi

  ## 4. Once the L1PAO has the two approvhashes, we execute the transaction permissionlessly.nested.just
  forge build
  execution=$(forge script ${script} \
    --rpc-url ${ANVIL_LOCALHOST_RPC} \
    --broadcast --private-key {{PRIVATE_KEY_EXECUTOR}} \
    --sig "runJson(string)" \
    ${bundlePath} 2>&1)

approve whichSafe hdPath='0' ledger='true':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
    echo "Using council safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "{{chainGovernorSafe}}" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is not set for chain-governor." >&2
      exit 1
    fi
    safe="{{chainGovernorSafe}}"
  fi
  if {{ledger}}; then
    sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    signer_args="--ledger --hd-paths \"m/44'/60'/{{hdPath}}'/0/0\""
  else
    signer_private_key=$(just --justfile={{justfile()}} get-keystore-private-key)
    signer_args="--private-key ${signer_private_key}"
  fi

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --broadcast \
    --sender ${sender} \
    --sig "approveJson(string,address,bytes)" \
    ${signer_args} \
    ${bundlePath} \
    ${safe} \
    ${signatures}

execute hdPath='0' ledger='true':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  if {{ledger}}; then
    sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    signer_args="--ledger --hd-paths \"m/44'/60'/{{hdPath}}'/0/0\""
  else
    signer_private_key=$(just --justfile={{justfile()}} get-keystore-private-key)
    sender=$(cast wallet address --private-key ${signer_private_key})
    signer_args="--private-key ${signer_private_key}"
  fi
  echo "Executed with sender: ${sender}"

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --broadcast \
    --sender ${sender} \
    --sig "runJson(string)" \
    ${signer_args} \
    ${bundlePath}

simulated-run hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --sender ${randomPersonEoa} \
    --sig "runJson(string)" \
    ${bundlePath}

