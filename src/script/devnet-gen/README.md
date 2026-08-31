# devnet-gen

Generates `src/tasks/sep/<NNN>-<template-slug>-<devnet-name>` task
directories from a Solidity template name plus a path to a devnet descriptor
in the [`devnets`](https://github.com/ethereum-optimism/devnets) repo.

## Usage

From the repo root:

```bash
# List available templates.
just gen-devnet-task list

# Show what an adapter consumes and where it pulls each input from.
just gen-devnet-task info OPCMUpgradeV600

# Generate a task. Defaults: source everything from the devnet, write to
# src/tasks/sep/<NNN>-<template-slug>-<devnet-name>/.
just gen-devnet-task OPCMUpgradeV600 ../devnets/alphanets/u18-alpha

# Override one or more inputs (repeat --override as needed).
just gen-devnet-task OPCMUpgradeV600 ../devnets/alphanets/u18-alpha \
    --override OPCM=0x1111111111111111111111111111111111111111

# OPCMUpgradeV800 defaults initBond to 0.08 ETH; override it only when needed.
just gen-devnet-task OPCMUpgradeV800 ../devnets/alphanets/u18-alpha \
    --override startingRespectedGameType=9

# Print the planned files without writing.
just gen-devnet-task OPCMUpgradeV600 ../devnets/alphanets/u18-alpha --dry-run

# Skip onchain checks (e.g. when working from a laptop without RPC access).
just gen-devnet-task OPCMUpgradeV600 ../devnets/alphanets/u18-alpha --offline

# Use a custom L1 RPC for the onchain check.
just gen-devnet-task OPCMUpgradeV600 ../devnets/alphanets/u18-alpha \
    --rpc-url https://my-internal-l1-rpc.example
```

## Onchain checks

After the adapter has produced the task config, the generator calls
`adapter.verify(devnet, task_files, rpc_url)` to do any onchain sanity
checks. For OPCM adapters this means calling `OPCM.version()` on the
resolved address and asserting it matches the version the template expects
(`6.0.0` for `OPCMUpgradeV600`, any `7.1.x` for `OPCMUpgradeV800`). A
mismatch aborts before any files are written.

L1 RPC URLs are hardcoded per L1 network in
[`networks.py`](./networks.py) (publicnode for sepolia/mainnet today). Pass
`--rpc-url <url>` to use a different RPC, or `--offline` to skip the check
entirely.

Dependencies are managed by [`uv`](https://docs.astral.sh/uv/) (pinned in
[`mise.toml`](../../../mise.toml)). On each invocation, `just gen-devnet-task`
runs `uv sync --frozen` to materialise the exact versions in
[`uv.lock`](./uv.lock) into `.venv/`. The lockfile pins every direct and
transitive dependency with a SHA-256 hash; nothing is fetched without
verification.

To bump a pinned version, edit [`pyproject.toml`](./pyproject.toml) and run
`uv lock` to regenerate `uv.lock`. Commit both files together.

## What gets written

For `OPCMUpgradeV600` against a devnet named `u18-alpha` whose first chain is
at chainId `420100007`, with the next free task slot in `sep/` being `076`:

```
src/tasks/sep/076-opcm-upgrade-v600-u18-alpha/
├── config.toml         # templateName, l2chains, [opcmUpgrades], [addresses].OPCM
├── addresses.json      # per-chainId L1 contract addresses (renamed where needed)
├── README.md           # boilerplate + auto-filled "Devnet Context" block; Status: DEVNET
├── VALIDATION.md       # boilerplate
└── .env                # TENDERLY_GAS=10000000
```

Devnet tasks live at the same depth as production-network tasks because
`just sign` / `just approve` / `just simulate` derive the network from the
parent directory's name. They're kept out of stacked simulations of the
parent network via the `Status: DEVNET` filter in
[../fetch-tasks.sh](../fetch-tasks.sh) — direct invocations from the task
directory still work normally.

## Adding a new adapter

1. Add the new template under [`src/template/`](../../template/) as usual.
2. Drop a single Python file under
   [`adapters/`](./adapters/) named `<lowercase_template_name>.py`.
3. Subclass `Adapter`, set `template_name` and `description`, implement
   `inputs()` (for `info` / `--help`) and `build(devnet, overrides)` (returning
   a `TaskFiles`).
4. For OPCM upgrades, subclass `_opcm.OPCMUpgradeAdapter` and declare the
   template-specific address sources and TOML fields.
5. Add a fixture under `tests/fixtures/devnets/` if your adapter reads any
   field the existing fixture doesn't cover, and a test under `tests/`.

The adapter registry auto-discovers public modules in `adapters/`, so
registration is implicit; helper modules should start with `_`.

## Running tests

```bash
cd src/script/devnet-gen
uv sync --frozen --group dev
uv run pytest
```
