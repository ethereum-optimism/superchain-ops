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
  # Retry to ride out transient proxy.golang.org / sum.golang.org errors.
  for attempt in 1 2 3; do
    GOBIN="$REPO_ROOT/bin" go install github.com/base/eip712sign@v0.0.11 && exit 0
    [ "$attempt" -lt 3 ] && echo "go install eip712sign failed (attempt $attempt/3), retrying in 10s..." >&2 && sleep 10
  done
  exit 1

clean:
  forge clean

compare-games before-game='' after-game='':
  bash src/script/compareGames.sh {{before-game}} {{after-game}}
