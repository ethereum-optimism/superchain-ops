install: install-foundry install-contracts install-eip712sign

# installs foundry at the version stored in .foundryrc
# foundryup must already be installed per the instructions in the root README
install-foundry:
  #!/usr/bin/env bash
  foundryup -C $(cat .foundryrc)

# install contract dependencies
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
