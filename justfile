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
  echo 'renaming lib/contracts to the more descriptive lib/base-contracts'
  mv lib/contracts lib/base-contracts

  forge install --no-git ethereum-optimism/optimism
  forge install --no-git OpenZeppelin/openzeppelin-contracts@v4.9.3
  forge install --no-git transmissions11/solmate@v7

  forge clean

install-eip712sign:
  go install github.com/base-org/eip712sign@v0.0.3
