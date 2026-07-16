# 061-ink-proposer-rotation

Status: READY TO SIGN

Simulated against the stacked signer nonces recorded in [config.toml](./config.toml) (L1PAO=36 / FUS=62 / SC=60; live `initBonds(1)` = 0.08 ETH confirmed). The proposer-only `gameArgs(1)` diff is confirmed (Gelato proposer fully replaced, challenger preserved); the nested signer domain/message/safe hashes in [VALIDATION.md](./VALIDATION.md) match `just simulate council` / `just simulate foundation` and only move if a signer-safe nonce advances.

> [!NOTE]
> This task reads the **live** `gameArgs(1)` and swaps **only the proposer**, so it carries whatever impl/prestate/vm/delayedWETH U19 set forward unchanged. Game type 1 is a dormant Guardian fallback; the active respected game post-Karst is permissionless CANNON_KONA (type 8), which has no on-chain proposer. Rotating the type-1 proposer to OPE is done **for correctness** (plan §1 / §2.3).

## Objective

For the **Ink mainnet** (chainId 57073) DisputeGameFactory, rotate the **PermissionedDisputeGame** (PDG, game type 1) **proposer** to the OP Enterprise (OPE) proposer as part of the Gelato → OPE rollup-operator migration. This is cutover step **4** of the _Ink Mainnet Migration — Engineering Plan_ (target cutover 2026-07-28). It is the mainnet counterpart of the Ink Sepolia rehearsal task `sep/102-ink-sepolia-proposer-rotation` (executed 2026-06-22).

The PDG is a **dormant safety fallback** (the active game post-Karst is the permissionless CANNON_KONA, game type 8, which has no on-chain proposer). Per plan §1 / §2.3 its proposer is still updated **for correctness**.

> [!NOTE]
> **Proposer only.** The challenger is **left unchanged** at `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (FoundationOperationsSafe, OP governance per plan §3.1 "Already OP governance — no action"; confirmed live on-chain). The OPE challenger key is **not** written on-chain by this task. The absolute **prestate is left unchanged**, read live at sign time. No FaultDisputeGame (CANNON/0) or CANNON_KONA (8) change is made here.

### Mechanism

Ink mainnet's DisputeGameFactory is expected **v1.6.1** post-U19 (plan §3.2 — verify against `standard-versions-mainnet.toml` before signing) and uses the **gameArgs blob pattern**: the PDG/FDG implementations are shared blueprints (their `proposer()` / `challenger()` / `absolutePrestate()` immutables read `0x0`); the per-chain values live in `DisputeGameFactory.gameArgs(gameType)`. `SetDisputeGameArgs` reads the live `gameArgs(1)`, overrides **only** the proposer, keeps every other field, and emits a single `setImplementation(1, sameImpl, newGameArgs)`.

Because the prestate (and all other fields) are read live at sign time, this task is robust to U19/Karst changes — it preserves whatever is live and swaps only the proposer. **Always re-simulate immediately before signing.**

- **DisputeGameFactoryProxy**: `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`
- **PDG impl (unchanged by this task)**: `0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e` (v2.4.0, live `gameImpls(1)`).
- **Signer**: L1 ProxyAdminOwner Safe `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (nested 2-of-2: Foundation Upgrade Safe `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` + Security Council `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`). Already OP governance — signatures collected in the warm phase (plan step W22), ≥72h before cutover.

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
cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameArgs(uint32)(bytes)" 1 --rpc-url mainnet
# Bytes 124..144 (proposer)  must equal 3832bfbef03173e4c49a00ec0dd178817a02d177
# Bytes 144..164 (challenger) must equal 9ba6e03d8b90de867373db8cf1a58d2f7f006b3a (unchanged)
```

Record the executed tx hash in the migration plan execution log (cutover step 4 / DisputeGameFactory.setImplementation).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
