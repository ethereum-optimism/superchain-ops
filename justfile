install: install-contracts install-eip712sign

# install dependencies
# for any tasks run in production, a specific commit should be used for each dep.
install-contracts:
  #!/usr/bin/env bash
  forge install

install-eip712sign:
  #!/usr/bin/env bash
  REPO_ROOT=`git rev-parse --show-toplevel`
  cd $REPO_ROOT
  cd lib/eip712sign
  go build
  cp eip712sign ../../bin
