set dotenv-load

export rpcUrl := env_var('ETH_RPC_URL')
export signatures := env_var_or_default('SIGNATURES', '')
export bundle := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()
export bundlePath := "${taskPath}/${bundleName}.json"

# Accounts
export OWNER_SAFE := env_var_or_default('FOUNDATION_SAFE', '0x847B5c174615B1B7fDF770882256e2D3E95b9D92')
export foundationOwner0 := "0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64"

simulate hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundle}.json
  echo "getting signer address..."
  if [ t"$SIMULATE_WITHOUT_LEDGER" == t1 ]
  then
    signer=${foundationOwner0}
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi
  echo "Simulating with: ${signer}"
  echo ""
  forge build
  forge script SignFromJson \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" ${bundlePath} \
    --sender ${signer}

sign taskPath hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundle}.json
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""
  forge build
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script SignFromJson \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" \
    ${bundlePath}

execute taskPath hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundle}.json
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  forge build
  forge script --fork-url ${ETH_RPC_URL} SignFromJson \
    --sig "runJson(string,bytes)" ${bundlePath} ${SIGNATURES} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" --broadcast \
    --sender ${sender}
