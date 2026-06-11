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
  bash src/script/compareGames.sh {{before-game}} {{after-game}}

# Generate a devnet ops task directory from a template + devnet path.
# Usage:
#   just gen-devnet-task list
#   just gen-devnet-task info OPCMUpgradeV600
#   just gen-devnet-task OPCMUpgradeV600 ../devnets/betanets/freya-u16
#   just gen-devnet-task OPCMUpgradeV600 ../devnets/alphanets/u18-alpha --override OPCM=0x...
gen-devnet-task *args:
  #!/usr/bin/env bash
  set -euo pipefail
  root_dir=$(git rev-parse --show-toplevel)
  gen_dir="${root_dir}/src/script/devnet-gen"
  # `uv sync --frozen` installs the exact versions from uv.lock (with hashes)
  # into .venv. It's a no-op when .venv is already in sync, so safe to call
  # on every invocation.
  uv --project "${gen_dir}" sync --frozen --quiet
  uv --project "${gen_dir}" run --frozen --quiet python "${gen_dir}/cli.py" {{args}}
