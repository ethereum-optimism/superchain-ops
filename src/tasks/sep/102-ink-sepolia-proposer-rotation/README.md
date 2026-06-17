# 102-ink-sepolia-proposer-rotation

Status: [READY TO SIGN] 

Re-simulated against live **post-U19** state (U19 executed 2026-06-15). The proposer-only `gameArgs(1)` diff is confirmed (old Gelato proposer fully replaced, challenger preserved); the nested signer domain/message hashes in [VALIDATION.md](./VALIDATION.md) match a fresh `just simulate council` / `just simulate foundation` run and only move if a signer-safe nonce advances.

> [!NOTE]
> U19 (executed 2026-06-15) bumped the Ink Sepolia permissioned (game type 1) implementation to v2.4.0 and set its absolute prestate to a `0xdead…` placeholder value. This does **not** disable the game — game type 1 stays a configured Guardian fallback (the active respected game is permissionless CANNON_KONA, type 8). Rotating its proposer to OPE remains the intended migration step. `SetDisputeGameArgs` reads the live `gameArgs(1)` and swaps only the proposer, so it carries U19's new impl/prestate/vm/delayedWETH forward unchanged.

## Objective

For the **Ink Sepolia** (chainId 763373) DisputeGameFactory on Sepolia, rotate the **PermissionedDisputeGame** (PDG, game type 1) **proposer** to the OP Enterprise (OPE) proposer as part of the Gelato → OPE rollup-operator migration. This is cutover step **4** of the _Ink Sepolia Testnet Migration — Engineering Plan_.

The PDG is a **dormant safety fallback** (the active game post-Karst is the permissionless CANNON_KONA, game type 8, which has no on-chain proposer). Per plan §1 / §2.3 its proposer is still updated **for correctness**.

> [!NOTE]
> **Proposer only.** The challenger is **left unchanged** at `0xfd1D2e729aE8eEe2E146c033bf4400fE75284301` — already the OP Sepolia challenger and OP governance (plan §3.1 "Already OP governance — no action"). The absolute **prestate is left unchanged**: it is owned by U19 (which set it to `0xdead…` on 2026-06-15) and read live at sign time. No FaultDisputeGame (CANNON/0) or CANNON_KONA (8) change is made here.

### Mechanism

Ink Sepolia's DisputeGameFactory is **v1.6.1** (post-U19) and uses the **gameArgs blob pattern**: the PDG/FDG implementations are shared blueprints (their `proposer()` / `challenger()` / `absolutePrestate()` immutables read `0x0`); the per-chain values live in `DisputeGameFactory.gameArgs(gameType)`. `SetDisputeGameArgs` reads the live `gameArgs(1)`, overrides **only** the proposer, keeps every other field, and emits a single `setImplementation(1, sameImpl, newGameArgs)`.

Because the prestate (and all other fields) are read live at sign time, this task was **robust to U19's changes** (executed 2026-06-15: prestate → `0xdead…`, impl → v2.4.0, new `vm`/`delayedWETH`) — it preserves whatever is live and swaps only the proposer. Always re-simulate immediately before signing.

- **DisputeGameFactoryProxy**: `0x860e626c700AF381133D9f4aF31412A2d1DB3D5d`
- **PDG impl (unchanged by this task; set by U19)**: `0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e` (v2.4.0)
- **Signer**: L1 ProxyAdminOwner Safe `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (nested 2-of-2: Foundation Upgrade Safe + Security Council). Already OP governance — collected in warm phase (plan step W22), ≥72h before cutover.

## State Changes

Writes to `DisputeGameFactoryProxy` ([`0x860e626c…3D5d`](https://sepolia.etherscan.io/address/0x860e626c700AF381133D9f4aF31412A2d1DB3D5d#readContract)) for chainId 763373.

### Game type 1 (PDG — PERMISSIONED_CANNON), `gameArgs(1)`

| Field | Bytes | Current (on-chain, post-U19) | New |
|-------|-------|------------------------------|-----|
| prestate | 0–32 | `0xdead000000000000000000000000000000000000000000000000000000000000` (placeholder set by U19) | unchanged (read live) |
| vm | 32–52 | `0xacc005dcd857b401e4732e6f7837135a22825cfa` | unchanged |
| anchorStateRegistry | 52–72 | `0x299d7ea9f0b584cfaf2a5341d151b44967594ca9` | unchanged |
| delayedWETH | 72–92 | `0x8ba4e89842c56eb8a45bfb37d186f4504e55f572` | unchanged |
| l2ChainId | 92–124 | `763373` | unchanged |
| **proposer** | 124–144 | `0xb15d792e30c5b7f67cbe5fe9ba76685b537b4543` (Gelato) | **`0x2282d49d805333D8cd6ddda52B32aC07d6e4e51B`** (OPE) |
| challenger | 144–164 | `0xfd1d2e729ae8eee2e146c033bf4400fe75284301` | unchanged (OP governance) |

`gameImpls(1)` is unchanged by this task at `0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e` (v2.4.0, set by U19); `initBonds(1)` stays `0.08 ETH`. Game types 0 (CANNON) and 8 (CANNON_KONA) are untouched.

- **Current values**: full `gameArgs(1)` read on-chain via `cast call 0x860e626c… "gameArgs(uint32)(bytes)" 1`, decomposed per the permissioned 164-byte layout.
- **New proposer**: OPE proposer (plan §3.3).

Plus the signer-safe nonces increment by 1.

## Execution order

Cutover step 4. Signatures collected in warm phase (plan W21/W22). Independent of the SystemConfig owner transfer (signed by the already-OP-governed L1PAO).

## Simulation & Signing

```bash
cd src/tasks/sep/102-ink-sepolia-proposer-rotation
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
# nested signing flow — see docs/NESTED.md:
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Post-execution verification

```bash
cast call 0x860e626c700AF381133D9f4aF31412A2d1DB3D5d "gameArgs(uint32)(bytes)" 1 --rpc-url <SEPOLIA_RPC>
# Bytes 124..144 (proposer)  must equal 2282d49d805333d8cd6ddda52b32ac07d6e4e51b
# Bytes 144..164 (challenger) must equal fd1d2e729ae8eee2e146c033bf4400fe75284301 (unchanged)
```

Record the executed tx hash in the migration plan execution log (cutover step 4 / DisputeGameFactory.setImplementation).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
