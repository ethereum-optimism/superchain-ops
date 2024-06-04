set dotenv-load

export rpcUrl := env_var('ETH_RPC_URL')
export deputyGuardianModuleAddr := env_var('DEPUTY_GUARDIAN_MODULE_ADDR')
export presignerSafe := env_var('PRESIGNER_SAFE')
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
    script=PresignPauseFromJson
    if [ -f "${taskPath}/PresignPauseFromJson.s.sol" ]; then
      script="${taskPath}/PresignPauseFromJson.s.sol:PresignPauseFromJson"
      echo "Running script with assertions"
    fi
    echo "Using script ${script}"
    REPO_ROOT=`git rev-parse --show-toplevel`
    PATH="$REPO_ROOT/bin:$PATH"
    export INPUT_JSON_PATH="${taskPath}/input.json"
    for nonce in ${PRESIGN_NONCES[@]}; do
      JSON_FILE="${taskPath}/tx/draft-${nonce}.json"
      if [ -z "$SIMULATE_WITHOUT_LEDGER" ]; then
        presigner \
          --workdir ${taskPath} \
          --script-name ${script} \
          --rpc-url ${rpcUrl} \
          --json-file $JSON_FILE \
          --ledger \
          --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
          sign
      else
        TEST_MNEMONIC="test test test test test test test test test test test junk"
        export FOUNDRY_SENDER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        export TEST_SENDER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        presigner \
          --workdir ${taskPath} \
          --script-name ${script} \
          --rpc-url ${rpcUrl} \
          --json-file $JSON_FILE \
          --mnemonic "$TEST_MNEMONIC" \
          --sender $TEST_SENDER \
          sign
      fi
    done

######################################
# Before the ceremony ...
######################################

prepare:
  #!/usr/bin/env bash
  set -x
  script=PresignPauseFromJson
  if [ -f "${taskPath}/PresignPauseFromJson.s.sol" ]; then
    script="${taskPath}/PresignPauseFromJson.s.sol:PresignPauseFromJson"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  REPO_ROOT=`git rev-parse --show-toplevel`
  PATH="$REPO_ROOT/bin:$PATH"
  echo Preparing transactions to sign...
  echo

  export INPUT_JSON_PATH="${taskPath}/input.json"
  mkdir -p ${taskPath}/tmp
  for nonce in ${PRESIGN_NONCES[@]}; do
    presigner \
      --workdir ${taskPath} \
      --script-name ${script} \
      --chain `cast chain-id` \
      --rpc-url ${rpcUrl} \
      --target-addr ${deputyGuardianModuleAddr} \
      --safe-addr ${presignerSafe} \
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
  script=PresignPauseFromJson
  if [ -f "${taskPath}/PresignPauseFromJson.s.sol" ]; then
    script="${taskPath}/PresignPauseFromJson.s.sol:PresignPauseFromJson"
    echo "Running script with assertions"
  fi
  REPO_ROOT=`git rev-parse --show-toplevel`
  PATH="$REPO_ROOT/bin:$PATH"
  export INPUT_JSON_PATH="${taskPath}/input.json"
  for nonce in ${PRESIGN_NONCES[@]}; do
    presigner \
      --workdir ${taskPath} \
      --script-name ${script} \
      --rpc-url ${rpcUrl} \
      --json-file ${taskPath}/tx/draft-${nonce}.json \
      verify
  done

simulate-all:
  #!/usr/bin/env bash
    script=PresignPauseFromJson
  if [ -f "${taskPath}/PresignPauseFromJson.s.sol" ]; then
    script="${taskPath}/PresignPauseFromJson.s.sol:PresignPauseFromJson"
    echo "Running script with assertions"
  fi
  REPO_ROOT=`git rev-parse --show-toplevel`
  PATH="$REPO_ROOT/bin:$PATH"
  export INPUT_JSON_PATH="${taskPath}/input.json"
  for nonce in ${PRESIGN_NONCES[@]}; do
    presigner \
      --workdir ${taskPath} \
      --script-name ${script} \
      --rpc-url ${rpcUrl} \
      --json-file ${taskPath}/tx/draft-${nonce}.json \
      simulate
  done
