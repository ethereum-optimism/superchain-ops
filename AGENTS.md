# AI Agent Guidance — superchain-ops

Guidance for AI coding agents (and humans) working in this repository. It
explains what this repo does, the non-negotiable safety constraints for
governance operations, and where the canonical workflow docs live.

This repo secures real value across the Superchain. Every task here ultimately
becomes a multisig transaction that changes protocol parameters, upgrades
contracts, or moves ownership. A mistake can be irreversible. Treat every change
as high-risk and verify at every level.

## What this repo is

superchain-ops contains governance operations for the Superchain: multisig
transaction tasks, upgrade procedures, and configuration changes. Each
governance action is a discrete, reviewable **task** with its own configuration
and an explicit validation file that signers use to confirm what they are
signing.

### Key concepts

- **Safe multisig** — multi-signature wallets control protocol parameters. Most
  operations require N-of-M signers, and many are *nested* (a Safe whose owners
  are themselves Safes).
- **Task** — a self-contained directory describing one governance action. Tasks
  are reusable instances built on top of templates.
- **Template** — reusable Solidity code that standardizes how a class of tasks is
  built and executed (for example `L2TaskBase`, `SimpleTaskBase`, `OPCMTaskBase`).
- **Validation file** — every task ships a `VALIDATION.md` so signers can
  independently verify they are approving the intended operation. When signing
  with a hardware wallet, signers see only cryptographic hashes, not
  human-readable details; the validation file bridges that gap with the expected
  domain/message hashes, a breakdown of the calls, and the expected state
  changes.
- **Simulation** — operations are simulated against forked mainnet/testnet state
  (via Tenderly) before they are signed, so every state diff can be reviewed in
  advance.

## Repository layout

- `src/tasks/eth/` — Ethereum mainnet tasks.
- `src/tasks/sep/` — Sepolia testnet tasks.
- `src/template/` — reusable Solidity templates for tasks.
- `src/script/` — Foundry scripts and helpers.
- `test/` — Foundry tests, including the template regression suite.
- `docs/` — canonical human-facing workflow documentation (see below).
- `runbooks/` — operational runbooks.

Tasks are named in ascending lexicographical order using the format
`[network]/[###]-[descriptive-name]` (for example `eth/001-first-task`). Run
`just task ls` from `src/` to see the current ordering for a network.

## Non-negotiable safety constraints

These apply to every governance task:

- **Every task has a `config.toml`, a `README.md`, and a `VALIDATION.md`.**
- **Calldata must be independently verifiable** — no opaque blobs. A reviewer
  must be able to reconstruct exactly what the transaction does.
- **Simulations must pass against forked state before signing.** Every state diff
  must be explainable; never sign or approve a task with an unexplained state
  change.
- **Every address reference must be verified** against the canonical
  [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry).
- **Timelock periods must be documented and respected** for upgrades.
- **`VALIDATION.md` must be complete** with the correct domain and message hashes
  and all expected state changes documented.

## Authoring a task

1. Scaffold from an existing template:

   ```bash
   cd src/
   just new task
   ```

   Follow the prompts to create a task directory with pre-populated `README.md`
   and `config.toml`.

2. Fill in the task configuration and write a complete `VALIDATION.md`.

3. Run a Tenderly simulation and review every state change before requesting
   review:

   ```bash
   just --dotenv-path $(pwd)/.env simulate
   ```

   For a task that depends on others, prefer the stacked simulation from `src/`:

   ```bash
   just simulate-stack <network> <your-task-name>
   ```

4. Open the Tenderly link, verify every state diff against your `VALIDATION.md`,
   and confirm there are no unexpected changes. As the author you are
   responsible for understanding the full impact; reviewers and signers rely on
   your analysis.

See [`docs/NEW_TASK_GUIDE.md`](docs/NEW_TASK_GUIDE.md) for the full task
lifecycle and the pre-submission checklist.

## Authoring a template

Templates standardize and secure task execution. Scaffold one with:

```bash
cd src/
just new template <l2taskbase|simpletaskbase|opcmtaskbase>
```

A new template must be exercised by the regression suite
(`test/tasks/Regression.t.sol`) with an accompanying example task, or CI
(`template_regression_tests`) will fail. See
[`docs/NEW_TEMPLATE_GUIDE.md`](docs/NEW_TEMPLATE_GUIDE.md).

## Building and testing

Dependencies are managed with [`mise`](https://mise.jdx.dev/); see
[`CONTRIBUTING.md`](CONTRIBUTING.md) for setup. Then:

```bash
just install          # build the repo (from the root)
cd src/ && just test  # run before requesting review on any PR
```

## Reviewing a task PR

Reviewers should reproduce the author's work independently rather than trusting
the description:

1. Verify every address against the Superchain Registry.
2. Re-run the simulation and confirm each state diff matches `VALIDATION.md`.
3. Independently verify the calldata — at least one reviewer must reconstruct it
   from first principles.
4. Confirm `VALIDATION.md` is complete and the task status is set appropriately.

## Canonical workflow docs

The `docs/` directory is the source of truth for detailed workflows:

| Document | Description |
|----------|-------------|
| [`docs/NEW_TASK_GUIDE.md`](docs/NEW_TASK_GUIDE.md) | Creating a new task from an existing template |
| [`docs/NEW_TEMPLATE_GUIDE.md`](docs/NEW_TEMPLATE_GUIDE.md) | Creating a new template |
| [`docs/SINGLE.md`](docs/SINGLE.md) | Single-safe execution workflow |
| [`docs/NESTED.md`](docs/NESTED.md) | Nested-safe execution workflow |
| [`docs/SINGLE-VALIDATION.md`](docs/SINGLE-VALIDATION.md) | Validation patterns for single-safe operations |
| [`docs/NESTED-VALIDATION.md`](docs/NESTED-VALIDATION.md) | Validation patterns for nested-safe operations |

For contribution setup and tooling, see [`CONTRIBUTING.md`](CONTRIBUTING.md).
