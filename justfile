install: install-contracts install-eip712sign

# install dependencies
# for any tasks run in production, a specific commit should be used for each dep.
install-contracts:
  #!/usr/bin/env bash
  echo 'deleting lib folder'
  rm -rf lib
  forge install --no-git foundry-rs/forge-std
  forge install --no-git safe-global/safe-contracts@v1.3.0
  forge install --no-git base-org/contracts
  forge install --no-git ethereum-optimism/optimism
  echo 'renaming lib/contracts to the more descriptive lib/base-contracts'
  mv lib/contracts lib/base-contracts

install-eip712sign:
  go install github.com/base-org/eip712sign@v0.0.3
