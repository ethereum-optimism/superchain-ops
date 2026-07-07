# 061-ink-proposer-rotation

Status: DRAFT — warm-phase preparation (plan W21/W22). Not ready to sign: the OPE proposer is a placeholder until warm-phase key generation (W1/W4) lands, and the `gameArgs(1)` blob must be re-read live post-Karst. Fill `TODO(W1)`, pin the live `initBonds(1)`, then `just simulate council` / `just simulate foundation` to generate the nested hashes recorded in [VALIDATION.md](./VALIDATION.md).

> [!NOTE]
> This task reads the **live** `gameArgs(1)` and swaps **only the proposer**, so it carries whatever impl/prestate/vm/delayedWETH U19 set forward unchanged. Game type 1 is a dormant Guardian fallback; the active respected game post-Karst is permissionless CANNON_KONA (type 8), which has no on-chain proposer. Rotating the type-1 proposer to OPE is done **for correctness** (plan §1 / §2.3).

## Objective

For the **Ink mainnet** (chainId 57073) DisputeGameFactory, rotate the **PermissionedDisputeGame** (PDG, game type 1) **proposer** to the OP Enterprise (OPE) proposer as part of the Gelato → OPE rollup-operator migration. This is cutover step **4** of the _Ink Mainnet Migration — Engineering Plan_ (target cutover 2026-07-28). It is the mainnet counterpart of the Ink Sepolia rehearsal task `sep/102-ink-sepolia-proposer-rotation` (executed 2026-06-22).

The PDG is a **dormant safety fallback** (the active game post-Karst is the permissionless CANNON_KONA, game type 8, which has no on-chain proposer). Per plan §1 / §2.3 its proposer is still updated **for correctness**.

> [!NOTE]
> **Proposer only.** The challenger is **left unchanged** — expected `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (OP mainnet Challenger, OP governance per plan §3.1 "Already OP governance — no action"; **CONFIRM in the mainnet role audit**). The absolute **prestate is left unchanged**, read live at sign time. No FaultDisputeGame (CANNON/0) or CANNON_KONA (8) change is made here.

### Mechanism

Ink mainnet's DisputeGameFactory is expected **v1.6.1** post-U19 (plan §3.2 — verify against `standard-versions-mainnet.toml` before signing) and uses the **gameArgs blob pattern**: the PDG/FDG implementations are shared blueprints (their `proposer()` / `challenger()` / `absolutePrestate()` immutables read `0x0`); the per-chain values live in `DisputeGameFactory.gameArgs(gameType)`. `SetDisputeGameArgs` reads the live `gameArgs(1)`, overrides **only** the proposer, keeps every other field, and emits a single `setImplementation(1, sameImpl, newGameArgs)`.

Because the prestate (and all other fields) are read live at sign time, this task is robust to U19/Karst changes — it preserves whatever is live and swaps only the proposer. **Always re-simulate immediately before signing.**

- **DisputeGameFactoryProxy**: `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`
- **PDG impl (unchanged by this task)**: read live `gameImpls(1)` on mainnet.
- **Signer**: L1 ProxyAdminOwner Safe `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (nested 2-of-2: Foundation Upgrade Safe `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` + Security Council `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`). Already OP governance — signatures collected in the warm phase (plan step W22), ≥72h before cutover.

## State Changes

Writes to `DisputeGameFactoryProxy` ([`0x10d7B350…12CD`](https://etherscan.io/address/0x10d7B35078d3baabB96Dd45a9143B94be65b12CD#readContract)) for chainId 57073.

### Game type 1 (PDG — PERMISSIONED_CANNON), `gameArgs(1)`

| Field | Bytes | Current (on-chain) | New |
|-------|-------|--------------------|-----|
| prestate | 0–32 | read live | unchanged |
| vm | 32–52 | read live | unchanged |
| anchorStateRegistry | 52–72 | read live | unchanged |
| delayedWETH | 72–92 | read live | unchanged |
| l2ChainId | 92–124 | `57073` | unchanged |
| **proposer** | 124–144 | current Gelato proposer (CONFIRM) | **`TODO(W1)` OPE proposer** |
| challenger | 144–164 | `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a` (CONFIRM) | unchanged (OP governance) |

`gameImpls(1)` and `initBonds(1)` are unchanged by this task (read live). Game types 0 (CANNON) and 8 (CANNON_KONA) are untouched.

- **Current values**: full `gameArgs(1)` read on-chain via `cast call 0x10d7B350… "gameArgs(uint32)(bytes)" 1`, decomposed per the permissioned 164-byte layout.
- **New proposer**: OPE proposer (plan §3.3).

Plus the signer-safe nonces increment by 1.

## Execution order

Cutover step 4. Signatures collected in the warm phase (plan W21/W22). **Non-blocking** — does not hold up the sequencer switch (fallback game is dormant; active game is permissionless type 8), but must be confirmed before cutover step 10 (OPE proposer start). Independent of the SystemConfig owner transfer (signed by the already-OP-governed L1PAO).

## Simulation & Signing

```bash
cd src/tasks/eth/061-ink-proposer-rotation
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
# nested signing flow — see docs/NESTED.md:
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Post-execution verification

```bash
cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameArgs(uint32)(bytes)" 1 --rpc-url <MAINNET_RPC>
# Bytes 124..144 (proposer)  must equal <OPE proposer>
# Bytes 144..164 (challenger) must equal 9ba6e03d8b90de867373db8cf1a58d2f7f006b3a (unchanged)
```

Record the executed tx hash in the migration plan execution log (cutover step 4 / DisputeGameFactory.setImplementation).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
