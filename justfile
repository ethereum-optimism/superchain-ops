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
  GOBIN="$REPO_ROOT/bin" go install github.com/base/eip712sign@v0.0.11

clean:
  forge clean

compare-games before-game='' after-game='':
  bash src/improvements/script/compareGames.sh {{before-game}} {{after-game}}
