set dotenv-load

export rpcUrl := env_var('ETH_RPC_URL')
export superchainConfigAddr := env_var('SUPERCHAIN_CONFIG_ADDR')
export safeAddr := env_var('SAFE_ADDR')
export taskPath := invocation_directory()

jsonFile := ''

######################################
# During the ceremony ...
######################################

install: install-presigner

install-presigner:
    #!/usr/bin/env bash
    REPO_ROOT=`git rev-parse --show-toplevel`
    PATH="$REPO_ROOT/bin:$PATH"
    cd $REPO_ROOT
    mkdir -p bin || true
    GOBIN="$REPO_ROOT/bin" go install github.com/ethereum-optimism/presigner@v0.0.4

whoami hdPath='0':
    #!/usr/bin/env bash
    REPO_ROOT=`git rev-parse --show-toplevel`
    PATH="$REPO_ROOT/bin:$PATH"
    if [ -z "$SIMULATE_WITHOUT_LEDGER" ]; then
      eip712sign --address --hd-paths "m/44'/60'/{{hdPath}}'/0/0" --ledger
    else
      eip712sign --address --mnemonic "test test test test test test test test test test test junk"
    fi

sign hdPath='0':
    #!/usr/bin/env bash
    set -x
    REPO_ROOT=`git rev-parse --show-toplevel`
    PATH="$REPO_ROOT/bin:$PATH"
    export INPUT_JSON_PATH="${taskPath}/input.json"
    for nonce in ${PRESIGN_NONCES[@]}; do
      JSON_FILE="${taskPath}/tx/draft-${nonce}.json"
      if [ -z "$SIMULATE_WITHOUT_LEDGER" ]; then
        presigner \
          --workdir . \
          --script-name SignFromInputJson \
          --rpc-url ${rpcUrl} \
          --json-file $JSON_FILE \
          --ledger \
          --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
          sign
      else
        presigner \
          --workdir ${taskPath} \
          --script-name SignFromInputJson \
          --rpc-url ${rpcUrl} \
          --json-file $JSON_FILE \
          --mnemonic "test test test test test test test test test test test junk" \
          --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
          sign
      fi
    done

######################################
# Before the ceremony ...
######################################

prepare:
  #!/usr/bin/env bash
  set -x
  REPO_ROOT=`git rev-parse --show-toplevel`
  PATH="$REPO_ROOT/bin:$PATH"
  echo creating 3 tx...
  echo

  export INPUT_JSON_PATH="${taskPath}/input.json"
  mkdir -p ${taskPath}/tmp
  for nonce in ${PRESIGN_NONCES[@]}; do
    presigner \
      --workdir ${taskPath} \
      --script-name SignFromInputJson \
      --chain `cast chain-id` \
      --rpc-url ${rpcUrl} \
      --target-addr ${superchainConfigAddr} \
      --safe-addr ${safeAddr} \
      --safe-nonce ${nonce} \
      --json-file ${taskPath}/tmp/tmp-${nonce}.json \
      create
    cat ${taskPath}/tmp/tmp-${nonce}.json | jq . > ${taskPath}/tx/draft-${nonce}.json
  done

######################################
# After the ceremony ...
######################################

merge:
  #!/usr/bin/env bash
  REPO_ROOT=`git rev-parse --show-toplevel`
  PATH="$REPO_ROOT/bin:$PATH"
  for nonce in ${PRESIGN_NONCES[@]}; do
    presigner \
      --rpc-url ${rpcUrl} \
      --json-file ${taskPath}/tx/draft-${nonce}.json \
      merge ${taskPath}/tx/draft-${nonce}.signer-*.json
  done

verify:
  #!/usr/bin/env bash
  REPO_ROOT=`git rev-parse --show-toplevel`
  PATH="$REPO_ROOT/bin:$PATH"
  export INPUT_JSON_PATH="${taskPath}/input.json"
  for nonce in ${PRESIGN_NONCES[@]}; do
    presigner \
      --workdir ${taskPath} \
      --script-name SignFromInputJson \
      --rpc-url ${rpcUrl} \
      --json-file ${taskPath}/tx/draft-${nonce}.json \
      verify
  done

simulate-all:
  #!/usr/bin/env bash
  REPO_ROOT=`git rev-parse --show-toplevel`
  PATH="$REPO_ROOT/bin:$PATH"
  export INPUT_JSON_PATH="${taskPath}/input.json"
  for nonce in ${PRESIGN_NONCES[@]}; do
    presigner \
      --workdir ${taskPath} \
      --script-name SignFromInputJson \
      --rpc-url ${rpcUrl} \
      --json-file ${taskPath}/tx/draft-${nonce}.json \
      simulate
  done
