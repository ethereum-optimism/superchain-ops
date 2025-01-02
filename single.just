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
  forge script -vvvvvvvv ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" ${bundlePath} \
    --broadcast --unlocked --sender 0x3041BA32f451F5850c147805F5521AC206421623  # 0x3041..1623 is a signer that contains ethers.
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
