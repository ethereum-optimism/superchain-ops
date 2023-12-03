install: install-contracts install-eip712sign

# install dependencies
# for any tasks run in production, a specific commit should be used for each dep.
install-contracts:
  #!/usr/bin/env bash

  echo 'deleting lib/base-contracts folder'
  rm -rf lib/base-contracts
  forge install --no-git base-org/contracts
  echo 'renaming lib/contracts to the more descriptive lib/base-contracts'
  mv lib/contracts lib/base-contracts

install-eip712sign:
  go install github.com/base-org/eip712sign@v0.0.3
