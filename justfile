install: install-contracts install-eip712sign

# install dependencies
# for any tasks run in production, a specific commit should be used for each dep.
install-contracts:
  #!/usr/bin/env bash
  forge install

install-eip712sign:
  #!/usr/bin/env bash
  REPO_ROOT=`git rev-parse --show-toplevel`
  PATH="$REPO_ROOT/bin:$PATH"
  cd $REPO_ROOT
  mkdir -p bin || true
  GOBIN="$REPO_ROOT/bin" go install github.com/base-org/eip712sign@v0.0.8

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

clean:
  forge clean
