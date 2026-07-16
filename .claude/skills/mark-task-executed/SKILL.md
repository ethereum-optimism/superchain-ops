---
name: mark-task-executed
description: Mark one or more superchain-ops tasks as EXECUTED by updating each task README's Status line to link the on-chain execution transaction, then open a PR. Use when a task (or batch of tasks) has been executed on-chain and someone shares the execution tx hash(es).
---

# Mark a superchain-ops task as EXECUTED

When a governance task has been executed on-chain, its `README.md` status line
must be updated from the pre-execution state to `EXECUTED` with a link to the
execution transaction. This is a docs-only change — no Solidity, config, or
validation files change.

## The convention

Every task `README.md` begins with a title and a status line:

```markdown
# 056-fus-rotation-1

Status: [READY TO SIGN]()
```

Marking it executed means replacing **only** the status line's label and link:

```markdown
Status: [EXECUTED](https://etherscan.io/tx/0x<hash>)
```

- The status label may currently be `[READY TO SIGN]()`, `[READY TO EXECUTE]()`,
  `[SIGNED]()`, etc. — replace whatever is there with `[EXECUTED](<tx-url>)`.
- **Network → explorer base URL:**
  - `src/tasks/eth/...` (Ethereum mainnet) → `https://etherscan.io/tx/<hash>`
  - `src/tasks/sep/...` (Sepolia) → `https://sepolia.etherscan.io/tx/<hash>`
  - For other networks, use that network's canonical block explorer tx URL.
- Do not touch any other line in the README, and do not edit `config.toml` or
  `VALIDATION.md`.

## Steps

1. **Map each task to its execution tx hash.** The requester usually provides
   them (e.g. "056 → 0xabc…"). Match by the leading task number. If a mapping is
   ambiguous, ask rather than guess — a wrong tx link on a governance task is a
   correctness bug.
2. **Find each task directory:** `src/tasks/<network>/<###>-<name>/README.md`.
   (`ls src/tasks/eth | grep '^056'`.)
3. **Edit the status line** per the convention above for each task.
4. **Verify** each edited line: `grep -rn '^Status:' src/tasks/**/README.md`.
   Confirm the label is `EXECUTED`, the hash matches what was provided, and the
   explorer base URL matches the network.
5. **Open a PR** (docs-only, no CI simulation needed). Use a title like
   `docs: mark <network> tasks <###>-<###> as EXECUTED`. List each task and its
   tx link in the body so reviewers can spot-check hashes against the explorer.

## Notes

- This is a fast, cheap, low-risk change: string edits to markdown status lines.
  Batch multiple tasks into one PR.
- Recent examples for the exact diff shape: PRs #1494, #1457, and the
  "executed" PRs in the merge history.
- Reviewers should confirm each tx hash on the linked explorer actually
  corresponds to the task's execution (correct Safe, correct calldata) before
  merging.
