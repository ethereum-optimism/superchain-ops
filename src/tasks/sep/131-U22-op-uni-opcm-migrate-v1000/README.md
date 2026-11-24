# 131-U22-op-uni-opcm-migrate-v1000

Status: [DRAFT, NOT READY TO SIGN]

Scaffold. Every U22 release input is a placeholder.

## Summary

| | |
|---|---|
| Target date | Dec 8, 2026, right after the upgrade |
| Depends on | [130-U22-op-ink-soneium-uni](../130-U22-op-ink-soneium-uni/README.md) (migrate requires every chain on the v10 OPCM). |
| Sequencing | Sepolia 2/3. Followed by [132-U22-op-uni-zk-v1000](../132-U22-op-uni-zk-v1000/README.md). Nonces L1PAO 63, FUS 87, SC 77. |

| Chain | Chain ID | Change |
|---|---|---|
| OP Sepolia Testnet | 11155420 | INTEROP, shared dispute contracts |
| Unichain Sepolia Testnet | 1301 | INTEROP, shared dispute contracts |

## Objective

`OPCMv2.migrate` (`OPCMMigrateV1000`) for OP Sepolia and Unichain Sepolia as one interop dependency set: deploys a shared ETHLockbox, DisputeGameFactory, AnchorStateRegistry and DelayedWETH, moves both chains' ETH into the shared lockbox, enables INTEROP and registers SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9) on the shared factory, respecting 9. One-way, invalidates prior withdrawal proofs. Ink Sepolia and Minato do not migrate.

## Open items

- [x] OPCM address: op-contracts/v10.0.0-rc.2 OPCM `0x91C167C7AfBd0D0ACc0AA7e4525e90B5CCcb76A7` (superchain-registry #1424, `standard-versions-sepolia.toml`).
- [ ] `expectedValidationErrors`: fill from the StandardValidator output once simulated.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [ ] Dependency-set kona interop prestate embedding OP Sepolia + Unichain Sepolia.
- [ ] Shared SUPER_PERMISSIONED proposer.
- [ ] Starting anchor (super root + L2 sequence number), set close to execution.
- [ ] Gas of the single atomic `migrate()` call (open question on #1626).
- [ ] Supernode with OP Sepolia + Unichain Sepolia, challenger/proposer/dispute-mon cut-over ready (infra, no ops task).

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/sep/131-U22-op-uni-opcm-migrate-v1000

just simulate-stack sep 131-U22-op-uni-opcm-migrate-v1000 council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 131-U22-op-uni-opcm-migrate-v1000 council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
