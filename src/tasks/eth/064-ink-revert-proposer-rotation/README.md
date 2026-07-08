# 064-ink-revert-proposer-rotation: ROLLBACK — restore Gelato proposer on the PDG

Status: DRAFT — CONTINGENCY / ROLLBACK. NOT READY TO SIGN. Use only if the Ink mainnet Gelato → OPE migration must be aborted.

## Objective

Restores the **original Gelato** proposer on the **Ink mainnet** (chainId 57073) DisputeGameFactory PermissionedDisputeGame (PDG, game type 1), reversing [`eth/061-ink-proposer-rotation`](../061-ink-proposer-rotation) (cutover step 4).

> [!NOTE]
> **Proposer only.** The challenger is left unchanged at `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (OP governance — it was never rotated during the migration). The prestate and every other `gameArgs(1)` field are read live and preserved.

### Mechanism

Same as the forward task: `SetDisputeGameArgs` reads the live `gameArgs(1)` on the v1.6.1 DisputeGameFactory, overrides **only** the proposer, and emits a single `setImplementation(1, sameImpl, newGameArgs)`. Because all other fields are read live at sign time, this task is robust to any interim state — always re-simulate immediately before signing.

- **DisputeGameFactoryProxy**: `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`
- **Signer**: L1 ProxyAdminOwner Safe `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (nested 2-of-2: Foundation Upgrade Safe `0x847B5c…9D92` + Security Council `0xc2819D…Bd03`) — unchanged OP governance, same signer as forward task 061.

> [!CAUTION]
> The restore proposer is the **pre-migration Gelato** proposer. Capture it on-chain **before** the forward migration executes (role audit §3.1 / execution log) and pin it in [config.toml](./config.toml) — do not guess.

## Rollback order

Independent of the SystemConfig owner reverts (062/063) — signed by the already-OP-governed L1PAO, so it can run at any point in the rollback. Recommended alongside step 2 of the rollback sequence (see [`062`](../062-ink-revert-system-config-owner)).

## State Changes

Writes to `DisputeGameFactoryProxy` for chainId 57073.

| Field | Bytes | Post-migration | Restore to |
|-------|-------|----------------|-----------|
| **proposer** | 124–144 | OPE proposer | `TODO` pre-migration Gelato proposer |
| challenger | 144–164 | `0x9ba6e03d…006b3a` | unchanged |
| all other fields | — | live | unchanged (read live) |

Plus the signer-safe nonces increment by 1.

## Simulation & Signing

```bash
cd src/tasks/eth/064-ink-revert-proposer-rotation
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
# nested signing flow — see docs/NESTED.md:
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Post-execution verification

```bash
cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameArgs(uint32)(bytes)" 1 --rpc-url mainnet
# Bytes 124..144 (proposer)  must equal <Gelato proposer>
# Bytes 144..164 (challenger) must equal 9ba6e03d8b90de867373db8cf1a58d2f7f006b3a (unchanged)
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
