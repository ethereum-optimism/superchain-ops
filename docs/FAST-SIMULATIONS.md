# Fast simulations

`just simulate` and `just simulate-stack` are bound by RPC latency, not by compiling or executing. A cold run makes
about 800 sequential RPC reads (accounts and storage slots). At about 0.13 s per request against the default public
RPC, that is about 2 minutes, even though forge uses only a few seconds of CPU. Background:
[#1629](https://github.com/ethereum-optimism/superchain-ops/issues/1629).

Foundry caches every read on disk per block (`~/.foundry/cache/rpc/<chain>/<block>`). The tips below make runs reuse
that cache, or avoid repeating the same reads across runs.

## TL;DR

| You want to… | Run | Typical time |
|---|---|---|
| Re-run a simulation a few times while authoring or reviewing | Nothing to do: `simulate*` recipes pin a rounded block automatically | ~2 min first run, ~5–15 s repeats |
| Check a nested task (or a whole stack) on **every** child safe | `just simulate-stack-all-safes <network> [task]` | one run instead of one per child safe |
| Keep the same state for a long review (>10 min) | `export FORK_BLOCK_NUMBER=<block>` with an archive RPC | repeats stay warm |
| Fast cold runs | `OVERRIDE_RPC_URL=<low-latency or local RPC>` | scales with RPC latency |

Measured on the eth `084`→`087` stack (U21 upgrade plus 3 follow-up tasks, 2 child safes):

| Approach | Time |
|---|---|
| 8 separate `simulate-stack` calls at the latest block (as in #1629) | ~16 min |
| `simulate-stack-all-safes eth`, cold cache (7 child-safe runs, 4 tasks) | 113 s |
| `simulate-stack-all-safes eth`, warm cache | 34 s |
| One `simulate-stack eth 084-… council`, warm cache | 11 s |

## 1. Automatic block pinning for `simulate*` recipes

When `FORK_BLOCK_NUMBER` is not set, `just simulate`, `just simulate-stack` and `just simulate-stack-all-safes` fork
the chain head **rounded down to a multiple of 50 blocks** (~10 minutes on L1). Every simulation inside that window
forks the same block and reuses the on-disk RPC cache. The chosen block is printed:

```
Pinned simulation fork block 26461150 (head 26461188 rounded down to a multiple of 50; ...)
```

Controls:

| Variable | Effect |
|---|---|
| `FORK_BLOCK_NUMBER=<n>` | Use exactly block `n` (unchanged behavior; a task `.env` can also set it). |
| `FORK_BLOCK_NUMBER=-1` | Use the latest block. |
| `SIM_FORK_BLOCK_ROUNDING=<n>` | Round to a multiple of `n` instead of 50. |
| `SIM_FORK_BLOCK_ROUNDING=1` | Disable rounding and use the latest block. |

`sign`, `sign-stack`, `approve` and `execute` are **not** affected: they always use the latest block (or an explicit
`FORK_BLOCK_NUMBER`).

The rounded block is at most 49 blocks old, so it stays inside the ~128-block window that non-archive RPCs (including
the default publicnode endpoint) can serve.

## 2. Simulate every child safe in one process

For a nested task, reviewers usually run the stack once per child safe (`foundation`, `council`, …). Each run
re-fetches the same state and re-executes every earlier task in the stack. Instead:

```bash
cd src/
just simulate-stack-all-safes eth                 # every non-terminal eth task
just simulate-stack-all-safes eth 087-my-task     # the stack up to and including 087-my-task
```

For every task in the stack, this:

- snapshots the fork;
- simulates the task once per child-safe path of its root safe (depth-2 paths are expanded when a depth-1 owner is
  itself a nested Safe; EOA and EIP-7702-delegated owners are skipped because they sign the root safe directly);
- reverts to the snapshot after each run, so the runs are independent;
- then advances the stack exactly like `simulate-stack` does, so later tasks see the same state.

Each run goes through the same `TaskManager.executeTask` path as a normal stacked simulation, so state-diff checks and
the `VALIDATION.md` domain/message hash checks run for every child safe. The output ends with a summary:

```
========== StackedSimulator: all-child-safes summary ==========
[PASS] 087-my-task | child safes 0x847B…9D92 -> root 0x5a0A…3d2A
         domain: 0xa4a9…2672  message: 0x925d…d29a  <- simulated safe
[PASS] 087-my-task | child safes 0xc281…Bd03 -> root 0x5a0A…3d2A
         domain: 0xdf53…e967  message: 0xca71…bf75  <- simulated safe
```

The recipe exits non-zero if any run fails. It is simulation-only: it refuses to run in stacked signing mode, because
it prints more than one data-to-sign.

## 3. Pinning a block for a long review

Automatic pinning moves to a new block every ~10 minutes. To keep one block for a longer session:

```bash
export FORK_BLOCK_NUMBER=$(cast block-number --rpc-url https://ethereum.publicnode.com)
```

> [!WARNING]
> The default publicnode RPC is **not an archive node**. Reads more than ~128 blocks (~25 minutes) behind the head fail
> with `HTTP error 403 ... Archive requests require a personal token`, unless the state is already in the local
> cache. For a pin that outlives that window, also set `OVERRIDE_RPC_URL` to an archive RPC.

## 4. Warm once, then run in parallel

Once the cache for a block is warm, each run uses only 2–3 s of CPU, so independent runs can run in parallel:

```bash
export FORK_BLOCK_NUMBER=$(cast block-number --rpc-url https://ethereum.publicnode.com)
just simulate-stack eth 087-my-task                 # cold: warms the cache
just simulate-stack eth 087-my-task foundation &    # warm: run the rest in parallel
just simulate-stack eth 087-my-task council &
wait
```

- Do **not** run cold simulations in parallel against publicnode: it rate-limits (HTTP 429) and returns
  `block not found`.
- Parallel runs write the same cache file. The last write wins, which is harmless.

## 5. Faster or local RPC

`OVERRIDE_RPC_URL` replaces the RPC for every recipe (`src/script/get-rpc-url.sh`). Cold-run time scales with
latency: an RPC at ~30 ms is about 4–5x faster than publicnode, and a local node makes cold runs as fast as warm ones.

A shared local fork works too, and every run then shares one in-memory fork:

```bash
B=$(cast block-number --rpc-url https://ethereum.publicnode.com)
anvil --fork-url https://ethereum.publicnode.com --fork-block-number "$B" &
export OVERRIDE_RPC_URL=http://127.0.0.1:8545 FORK_BLOCK_NUMBER="$B"
```

Set `FORK_BLOCK_NUMBER` to the anvil fork block (or `SIM_FORK_BLOCK_ROUNDING=1`). Otherwise automatic pinning
rounds down to a block before the fork, which anvil cannot serve.

## Other tips

- `simulate-stack` no longer starts a separate `forge script … listStack` process: the simulator prints the stack
  order itself. This saves ~4 s per call.
- Stacked simulations hide most of the decoded output by default. Use `SIGNING_MODE_IN_PROGRESS=false` to print the
  full state diff.
- `SKIP_DECODE_AND_PRINT=1` skips decoding and printing for faster runs, but no markdown is printed.
- L2 forks made by a template (for example `vm.createSelectFork(l2RpcUrl)`) always use the L2 head and are not
  pinned. Their state is small.
- Compiler settings are not a bottleneck: when nothing changed, forge prints "No files changed, compilation skipped".

## Do not trade safety for speed

- **Results are frozen at the simulated block.** After any related on-chain execution, and before signing, re-run at
  the latest block (`FORK_BLOCK_NUMBER=-1` or `SIM_FORK_BLOCK_ROUNDING=1`). `sign`/`sign-stack` always use the latest
  block, and signers must still match the hashes they sign against `VALIDATION.md`.
- **Do not use `FETCH_TASKS_ONLY` to skip earlier tasks in the stack.** It breaks Safe nonces, and therefore the hashes,
  whenever tasks share a Safe.
- `simulate-stack-all-safes` replaces running the simulation once per child safe. It does **not** replace reviewing the
  Tenderly state diff for the child safe you sign with.
