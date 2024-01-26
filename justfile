install: install-contracts install-eip712sign

# install dependencies
# for any tasks run in production, a specific commit should be used for each dep.
install-contracts:
  #!/usr/bin/env bash
  forge install

install-eip712sign:
  #!/usr/bin/env bash
  cd ~
  git clone https://github.com/ethereum-optimism/eip712sign.git
  cd eip712sign
  go build
  go install
