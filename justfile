install: install-contracts install-eip712sign

# install dependencies
# for any tasks run in production, a specific commit should be used for each dep.
install-contracts:
  #!/usr/bin/env bash
  forge install

install-eip712sign:
  go install github.com/base-org/eip712sign@v0.0.3
