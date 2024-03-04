install: install-contracts install-eip712sign

# install dependencies
# for any tasks run in production, a specific commit should be used for each dep.
install-contracts:
  #!/usr/bin/env bash
  forge install

# install-eip712sign depends on install-contracts because the
# lib/eip712sign submodule needs to be installed by forge install.
install-eip712sign: install-contracts
  #!/usr/bin/env bash
  REPO_ROOT=`git rev-parse --show-toplevel`
  cd $REPO_ROOT
  mkdir -p bin || true
  cd lib/eip712sign
  go build
  cp eip712sign ../../bin

# Bundle path should be provided including the .json file extension.
add-transaction bundlePath to sig *params:
  #!/usr/bin/env bash
  bundleBaseName=$(echo {{bundlePath}} | xargs -I{} basename {} .json)
  dirname=$(echo {{bundlePath}} | xargs -I{} dirname {})
  # bundleBasePath is the path to the bundle without the .json extension
  bundleBasePath=${dirname}/${bundleBaseName}
  newBundlePath=${bundleBasePath}-new.json
  backupBundlePath=${bundleBasePath}-$(date -u '+%Y-%m-%d_%H-%M-%S').json
  DATA=$(cast calldata '{{sig}}' {{params}})
  echo DATA: $DATA
  echo bundlePath: {{bundlePath}}
  echo newBundlePath: $newBundlePath
  jq --arg to {{to}} --arg data ${DATA} '.transactions += [{"to": $to, "data": $data}]' {{bundlePath}} > ${newBundlePath}
  mv {{bundlePath}} ${backupBundlePath}
  mv ${newBundlePath} {{bundlePath}}
  echo "Old bundle backed up to ${backupBundlePath}."
