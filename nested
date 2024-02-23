set dotenv-load

export rpcUrl := env_var_or_default('ETH_RPC_URL', 'https://ethereum.publicnode.com')
export signatures := env_var_or_default('SIGNATURES', '')
export bundle := "input"
export location := `pwd`

# Accounts
export councilSafe := "0xc2819DC788505Aac350142A7A707BF9D03E3Bd03"
export councilOwner0 := "0x07dC0893cAfbF810e3E72505041f2865726Fd073"

export foundationSafe := "0x847B5c174615B1B7fDF770882256e2D3E95b9D92"
export foundationOwner0 := "0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64"

export ownerSafe := env_var('OWNER_SAFE')
export randomPersonEoa := "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"

simulate whichSafe taskPath hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${location}/{{taskPath}}/${bundle}.json
  echo "getting signer address..."
  if [ t"{{whichSafe}}" == t"foundation" ]; then
    safe="${foundationSafe}"
    signer="${foundationOwner0}"
    echo "signer: ${signer}"
    echo "safe: ${safe}"
  fi
  if [ t"{{whichSafe}}" == t"council" ]; then
    safe="${councilSafe}"
    signer="${councilOwner0}"
    echo "signer: ${signer}"
    echo "safe: ${safe}"
  fi
  echo "Simulating call to the {{whichSafe}} safe at ${safe}"
  if [ t"$SIMULATE_WITHOUT_LEDGER" != t1 ]; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    echo "Simulating with ledger account: ${signer}"
    else
      echo "Simulating without ledger using the first owner account: ${signer}"
  fi
  echo ""
  forge script NestedSignFromJson \
    --rpc-url ${rpcUrl} \
    --sender ${signer} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    "${safe}"

sign whichSafe taskPath hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${location}/{{taskPath}}/${bundle}.json
  cd ../../..
  if [ t"{{whichSafe}}" == t"foundation" ]; then
    safe="${foundationSafe}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ t"{{whichSafe}}" == t"council" ]; then
    safe="${councilSafe}"
    echo "Using council safe at ${safe}"
  fi
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script NestedSignFromJson \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    "${safe}"

execute whichSafe taskPath hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${location}/{{taskPath}}/${bundle}.json
  cd ../../..
  if [ t"{{whichSafe}}" == t"foundation" ]; then
    safe="${foundationSafe}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ t"{{whichSafe}}" == t"council" ]; then
    safe="${councilSafe}"
    echo "Using council safe at ${safe}"
  fi
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  forge script NestedSignFromJson \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "approveJson(string,address,bytes)" \
    ${bundlePath} \
    "${safe}" \
    "${signatures}"

simulated-run taskPath hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${location}/{{taskPath}}/${bundle}.json
  cd ../../..
  forge script NestedSignFromJson \
    --fork-url ${rpcUrl} \
    --sender ${randomPersonEoa} \
    --sig "runJson(string)" \
    ${bundlePath}
