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
    GOBIN="$REPO_ROOT/bin" go install github.com/ethereum-optimism/presigner@v0.0.5

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
    if [ -n "$SCRIPT" ]; then
      script=$SCRIPT
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
  if [ -n "$SCRIPT" ]; then
    script=$SCRIPT
  fi
  echo "Using script ${script}"
  REPO_ROOT=`git rev-parse --show-toplevel`
  PATH="$REPO_ROOT/bin:$PATH"
  echo Preparing transactions to sign...
  echo
  if [ -n "$SCRIPT" ]; then
    script=$SCRIPT
  fi

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
  if [ -n "$SCRIPT" ]; then
    script=$SCRIPT
  fi
  echo "Using script ${script}"
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
  if [ -n "$SCRIPT" ]; then
    script=$SCRIPT
  fi
  echo "Using script ${script}"
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

upload-PSPs:
 #!/bin/bash
 # Navigate to the directory containing the JSON files
 # Uncomment and modify the next line if you need to change directories
 echo "=================== PSPs Uploader ============================="
 echo "This is about to Upload the PSPs (ready-X.sh.b64 and ready-X.json) to 1Password"
 echo "Please make sure you have the files in the tx/ folder, if the PSPs is already uploaded this will duplicate it."
 # Check if there is one-password cli installed on the system.
 if which op >/dev/null 2>&1; then
    echo "op (one-password cli) is installed."
 else
    echo "op is not installed, please install op (one-password cli) using homebrew."
    exit
 fi

 cd $taskPath/tx
 # Loop through all files matching the pattern "ready-*.json"
 whereis op
 for file in ready-*; do
     # Check if the file exists to avoid errors with non-existent glob matches
     echo " file: "$file""
     if [[ -f "$file" ]]; then
         # Execute the command using the current file
         cat "$file" | op document create --file-name "$file" --vault="Pre-signed Pause OP Sepolia"
     else
         echo "No files found matching the pattern."
     fi
 done
 echo "========================= READ ====================================="
 echo "Make sure you run the just zip-PSPs command to share them with Base."
 echo "Now, make sure the PSPs are not empty into the 1Password (i.e. the signatures must be present)."
 echo "[⚠️IMPORTANT STEP⚠️] Remove the PSPs you received from Slack, and also on the current folder (remove all the signatures that could help an attacker executing this)!"

zip-PSPs:
 #!/bin/bash
 echo "=================== PSPs Zipping ============================="
 echo "This script will ZIP the PSPs into an archive encrypted with a Password (that is asked into the stdin)"
 echo "This will be helpful for sharing the PSPs with BASE for example."
 DATE=`date +%d-%m-%Y_%H-%M`
 ZIPNAME=/tmp/psps_$DATE.zip
 FOLDERNAME=/tmp/psps_$DATE
 if which zip >/dev/null 2>&1; then
    echo "zip is installed."
 else
    echo "zip is not installed, please install zip using homebrew."
    exit
 fi
 cd $taskPath/tx
 mkdir $FOLDERNAME
 cp ready-* $FOLDERNAME
 echo "Make sure all the ready are inside the folder:"
 ls -lrta $FOLDERNAME
 ## zip with the password
 echo "Please enter the password for the ZIP file:"
 zip -e -r $ZIPNAME $FOLDERNAME
 file $ZIPNAME
 echo "Content of the ZIP archive:"
 unzip -l $ZIPNAME
 rm -rf $FOLDERNAME 
 echo "The file $ZIPNAME is zipped with the password and is ready to be shared to unzip please use the command:"
 echo "Make sure again to not let any sensitive information the folder."
 echo "unzip $ZIPNAME"
