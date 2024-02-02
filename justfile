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
