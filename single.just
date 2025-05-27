set dotenv-load

export rpcUrl := env_var('ETH_RPC_URL')
export signatures := env_var_or_default('SIGNATURES', '')
export bundleName := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()
export ownerSafe := env_var('OWNER_SAFE')


# Keystore variables
export keystorePathBase := "~/.foundry/keystores/"

PRIVATE_KEY_OWNER := "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
PRIVATE_KEY_EXECUTOR :="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
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
  sender=$(cast wallet address --private-key ${signer_private_key})
  echo "Signing with the signer: ${sender}" >&2
  if [ -z "${signer_private_key}" ]; then
    echo "Error: Failed to get private key for keystore ${keystorePath}" >&2
    exit 1
  fi
  echo "${signer_private_key}"

approvehash_in_anvil hdPath='0':
  #!/usr/bin/env bash
  echo "simulating in anvil"
  localrpcUrl="http://localhost:8545"
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
  fi

  echo "Using script ${script} with simulate_in_anvil."
  echo "Safe address: ${ownerSafe}"
  echo "Getting signer address..."

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --private-key  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80) # corresponding to 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 private-key.
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi
  echo "Simulating with: ${signer}"
  echo ""
  
  echo "============ OVERRIDE SAFE SETTINGS '${ownerSafe}' ============"
  echo "1. Set the threshold to 1."
  cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000004 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${localrpcUrl}

  echo "2.set the owner count to 1."
  ## 2. Set the owner count to 1.
  cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000003 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${localrpcUrl}

  echo "3.Insert the address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 as the sole owner of the safe."
  ## 3. Set the 0xf39 address to the sole signer of the safe.
  # cast keccak 1 || 2 => 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 expected owner mapping: {0x1 -> 0xf39..., 0xf39 -> 0x1}
  cast rpc anvil_setStorageAt ${ownerSafe} 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 0x000000000000000000000000f39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url ${localrpcUrl}
  ## 4. Set the owner (abi.encode(owner, uint256(2)))-> to sentinel_address (0x1).
  echo "4.Close the mapping of the owners to the sentinel address."
  cast rpc anvil_setStorageAt ${ownerSafe} 0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1  0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${localrpcUrl}

  echo "the sole Owner of the ${ownerSafe} is: $(cast call ${ownerSafe}  "getOwners()(address[])" --rpc-url http://localhost:8545)"
  echo "================================================"
  # sender=$(cast wallet address --private-key  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
  
  forge build

  signer_tenderly=$(cast call ${ownerSafe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)
  tenderly_link=$(forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sender ${signer_tenderly} \
    --sig "signJson(string)" \
    ${bundlePath})

  echo "Tenderly link: $tenderly_link" 

  outputforge=$(forge script ${script} \
    --rpc-url ${localrpcUrl} \
    --sig "signJson(string)" ${bundlePath} \
    --sender ${signer})
  tempfile=$(mktemp)
  echo "tmp file located to:" > $tempfile
  echo "Outputforge: $outputforge" > $tempfile   

  hash=$(cat $tempfile | grep -A 1 "If submitting onchain, call Safe.approveHash on " | cut -d ':' -f 2 | tr -d '[:space:]')
  # hash=$(echo $outputforge | grep -A 1 "If submitting onchain, call Safe.approveHash" "$file_path" | tail -n 1 | awk '{print $2}')

  # Check if a hash was found
  if [[ -z "$hash" ]]; then
      echo "Hash not found in the file."
      exit 1
  else
      echo "Extracted Hash: $hash"
  fi

  ## 5. Approve the hash with the well-known private key that is the first owner of anvil selection.
  cast send ${ownerSafe} "approveHash(bytes32)" ${hash} --rpc-url ${localrpcUrl} --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 # &> /dev/null
 
simulate hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
  fi

  echo "Using script ${script}"
  echo "Safe address: ${ownerSafe}"
  echo "Getting signer address..."

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast call ${ownerSafe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi
  echo "Simulating with: ${signer}"
  echo ""

  root_dir=$(git rev-parse --show-toplevel)
  if [ "${FOUNDRY_PROFILE}" == "ci" ]; then
    if [[ "${rpcUrl}" == *"sep"* ]]; then
      ETH_RPC_URL=$(yq eval ".profile.ci.rpc_endpoints.sepolia" "${root_dir}/foundry.toml")
    else
      ETH_RPC_URL=$(yq eval ".profile.ci.rpc_endpoints.mainnet" "${root_dir}/foundry.toml")
    fi
    export ETH_RPC_URL
  fi

  forge build
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" ${bundlePath} \
    --sender ${signer}
sign hdPath='0' ledger='true':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
  fi
  echo "Using script ${script}"
  echo "getting signer address..."
  if {{ledger}}; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    signer_args="--ledger --hd-paths \"m/44'/60'/{{hdPath}}'/0/0\""
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
    --sig "signJson(string)" \
    ${bundlePath}

execute_in_anvil hdPath='0':
  #!/usr/bin/env bash
  localrpcUrl="http://localhost:8545" # Can be set as global in the future.
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
  fi

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80) # corresponding to 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 private-key.
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi
  echo "Simulating with: ${signer}"
  echo "Using script ${script}"
  forge build
  execution=$(forge script ${script} \
    --rpc-url ${localrpcUrl} \
    --sig "runJson(string,bytes)" ${bundlePath} ${FAKE_SIG} \
    --broadcast --private-key {{PRIVATE_KEY_EXECUTOR}} 2>&1)
  echo $execution


execute hdPath='0' ledger='true':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
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
  echo "Executing with sender: ${sender}"

  forge build
  forge script --fork-url ${ETH_RPC_URL} ${script} \
    --sig "runJson(string,bytes)" ${bundlePath} ${SIGNATURES} \
    --broadcast \
    --sender ${sender} \
    ${signer_args}
