set dotenv-load

export rpcUrl := env_var('ETH_RPC_URL')
export signatures := env_var_or_default('SIGNATURES', '')
export bundleName := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()
export ownerSafe := env_var('OWNER_SAFE')

simulate hdPath='0' rpcUrlExternal="" broadcast="false":
  #!/usr/bin/env bash
  if [[ {{rpcUrlExternal}} == "" ]]; then
    rpcUrl=${rpcUrl}
  else
    rpcUrl={{rpcUrlExternal}}
  fi
  echo "rpcUrl: ${rpcUrl}"
  echo "value of the broadcast {{broadcast}}"
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

  forge build
  if [[ "{{broadcast}}" == "true" ]]; then
  echo "Broadcasting transaction..."
  echo ${rpcUrl}
  # cast rpc anvil_impersonateAccount 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url ${rpcUrl} #Impersonate the account 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 that has prefunded ETH. 
    # cast send ${signer} --value 10ether --rpc-url ${rpcUrl} --from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --unlocked # Prefund some ETH


  # cast rpc anvil_stopImpersonatingAccount 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url ${rpcUrl} #Stop impersonating the account 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  #
  # cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000004 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${rpcUrl} 
  ## 1. Set the threshold to 1.
  echo "============ OVERRIDE SAFE SETTINGS ============"
  echo "1. Set the threshold to 1."
  cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000004 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${rpcUrl}
  
  echo "2.set the owner count to 1."
  ## 2. Set the owner count to 1.
  cast rpc anvil_setStorageAt ${ownerSafe} 0x0000000000000000000000000000000000000000000000000000000000000003 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${rpcUrl}

  echo "3.Insert the address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 as the sole owner of the safe."
  ## 3. Set the 0xf39 address to the sole signer of the safe.
  # cast keccak 1 || 2 => 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 expected owner mapping: {0x1 -> 0xf39..., 0xf39 -> 0x1}
  cast rpc anvil_setStorageAt ${ownerSafe} 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 0x000000000000000000000000f39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url ${rpcUrl}
  ## 4. Set the owner (abi.encode(owner, uint256(2)))-> to sentinel_address (0x1).
  echo "4.Close the mapping of the owners to the sentinel address."
  cast rpc anvil_setStorageAt ${ownerSafe} 0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1  0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${rpcUrl}

  cast call 0x847B5C174615B1B7FDF770882256E2D3E95B9D92  "getOwners()" --rpc-url http://localhost:8545
  echo "================================================"
  forge script -vvvvvvv ${script} \
    --rpc-url ${rpcUrl} \
    --sig "runJson(string,bytes)" ${bundlePath} 11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111 \
    --broadcast --skip-simulation --sender  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

  else
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" ${bundlePath} \
    --sender ${signer}
  fi
sign hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
  fi
  echo "Using script ${script}"
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""

  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" \
    ${bundlePath}

execute hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
  fi
  echo "Using script ${script}"
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script --fork-url ${ETH_RPC_URL} ${script} \
    --sig "runJson(string,bytes)" ${bundlePath} ${SIGNATURES} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" --broadcast \
    --sender ${sender}
