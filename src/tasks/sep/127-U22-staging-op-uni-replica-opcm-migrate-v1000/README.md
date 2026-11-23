# 127-U22-staging-op-uni-replica-opcm-migrate-v1000

Status: [DRAFT, NOT READY TO SIGN]

Scaffold. Every U22 input and both redeployed chains are placeholders.

## Summary

| | |
|---|---|
| Target date | Nov 23, 2026, right after the upgrade |
| Depends on | [126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000](../126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000/README.md) (migrate requires every chain on the v10 OPCM). |
| Sequencing | Staging 2/3. Followed by [128-U22-staging-op-uni-replica-zk-v1000](../128-U22-staging-op-uni-replica-zk-v1000/README.md). Staging PAO nonce 159. |

| Chain | Chain ID | Change |
|---|---|---|
| stg-op-replica | 420130023 | INTEROP, shared dispute contracts |
| stg-uni-replica | 420130024 | INTEROP, shared dispute contracts |

## Objective

`OPCMv2.migrate` (`OPCMMigrateV1000`) for stg-op-replica and stg-uni-replica as one interop dependency set: deploys a shared ETHLockbox, DisputeGameFactory, AnchorStateRegistry and DelayedWETH, moves the ETH into the shared lockbox, enables INTEROP and registers SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9) on the shared factory, respecting 9. One-way, invalidates prior withdrawal proofs.

## Open items

- [x] OPCM address: op-contracts/v10.0.0-rc.2 OPCM `0x91C167C7AfBd0D0ACc0AA7e4525e90B5CCcb76A7` (superchain-registry #1424, `standard-versions-sepolia.toml`).
- [ ] `expectedValidationErrors`: fill from the StandardValidator output once simulated.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [ ] Replica contract addresses (`addresses.json`) once deployed.
- [ ] Dependency-set kona interop prestate embedding both chains.
- [ ] Shared SUPER_PERMISSIONED proposer.
- [ ] Starting anchor (super root + L2 sequence number), set close to execution.
- [ ] Supernode, challenger and proposer cut-over ready (infra, no ops task).

## Simulation & Signing

This is a **single-safe** task, so no child-safe argument is needed.

```bash
cd src/tasks/sep/127-U22-staging-op-uni-replica-opcm-migrate-v1000

just simulate-stack sep 127-U22-staging-op-uni-replica-opcm-migrate-v1000

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 127-U22-staging-op-uni-replica-opcm-migrate-v1000
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
