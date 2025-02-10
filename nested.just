set dotenv-load

export rpcUrl := env_var_or_default('ETH_RPC_URL', 'https://ethereum.publicnode.com')
export signatures := env_var_or_default('SIGNATURES', '')
export bundleName := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()

# Accounts
export councilSafe := env_var("COUNCIL_SAFE")
export foundationSafe := env_var("FOUNDATION_SAFE")
export ownerSafe := env_var('OWNER_SAFE')
export chainGovernorSafe := env_var_or_default('CHAIN_GOVERNOR_SAFE', '')
export randomPersonEoa := "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"

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

sign whichSafe hdPath='0':
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
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""

  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    "${safe}"

approvehash_in_anvil whichSafe hdPath='0':
  #!/usr/bin/env bash
  # set -x
  localrpcUrl="http://localhost:8545"
  # sender=$(cast wallet address --private-key  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  echo "simulating in anvil"
  localrpcUrl="http://localhost:8545"

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
    signer=$(cast wallet address --private-key  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80) # corresponding to 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 private-key.
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi

  echo "Simulating with: ${signer}"
  echo ""
  
  echo "============ OVERRIDE SAFES SETTINGS '${ownerSafe}' & '${safe}' ============"
  echo "0. Set the threshold of the L1PAO to 1."
  cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000004 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${localrpcUrl}
  echo "1. Set the threshold to 1 of the child safe."
  cast rpc anvil_setStorageAt ${safe} 0x0000000000000000000000000000000000000000000000000000000000000004 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${localrpcUrl}

  echo "2. Set the owner count to 1."
  ## 2. Set the owner count to 1.
  cast rpc anvil_setStorageAt ${safe} 0x0000000000000000000000000000000000000000000000000000000000000003 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${localrpcUrl}


  echo "3. Insert the address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 as the sole owner of the safe."
  ## 3. Set the 0xf39 address to the sole signer of the safe.
  # cast keccak 1 || 2 => 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 expected owner mapping: {0x1 -> 0xf39..., 0xf39 -> 0x1}
  cast rpc anvil_setStorageAt ${safe} 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 0x000000000000000000000000f39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url ${localrpcUrl}
  ## 4. Set the owner (abi.encode(owner, uint256(2)))-> to sentinel_address (0x1).
  echo "4. Close the mapping of the owners to the sentinel address."
  cast rpc anvil_setStorageAt ${safe} 0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1  0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${localrpcUrl}

  echo "the sole Owner of the \"${safe}\" is: $(cast call ${safe}  "getOwners()(address[])" --rpc-url http://localhost:8545)"
  echo "================================================"
  
  forge build
  outputforge=$(forge script ${script} \
    --rpc-url ${localrpcUrl} \
    --broadcast \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --sender ${signer} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    ${safe})
  echo "Outputforge: $outputforge" > /tmp/outputforge.txt
  hash=$(cat /tmp/outputforge.txt | grep -A 1 "If submitting onchain, call Safe.approveHash on " | cut -d ':' -f 2 | tr -d '[:space:]')

  # Check if a hash was found
  if [[ -z "$hash" ]]; then
      echo "Hash not found in the file."
      exit 1
  else
      echo "Extracted Hash: $hash"
  fi
  
  ## 5. Approve the hash with the well-known private key that is the first owner of anvil selection.
  cast send ${safe} "approveHash(bytes32)" ${hash} --rpc-url ${localrpcUrl} --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  forge script ${script} \
    --rpc-url ${localrpcUrl} \
    --broadcast \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --sig "approveJson(string,address,bytes)" \
    ${bundlePath} \
    ${safe} \
    1111 # dummy signature to pass the check if the signature is not empty..


approve whichSafe hdPath='0':
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
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "approveJson(string,address,bytes)" \
    ${bundlePath} \
    ${safe} \
    ${signatures}

execute hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "runJson(string)" \
    ${bundlePath}

execute_in_anvil hdPath='0':
  #!/usr/bin/env bash
  localrpcUrl="http://localhost:8545"
  # set -x
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80) # corresponding to 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 private-key.
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi
 

  forge build
  forge script ${script} \
    --rpc-url ${localrpcUrl} \
    --broadcast --sender  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --sig "runJson(string)" \
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
