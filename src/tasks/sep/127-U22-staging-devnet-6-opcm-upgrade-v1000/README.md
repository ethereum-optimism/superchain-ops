# 127-U22-staging-devnet-6-opcm-upgrade-v1000

Status: [DRAFT, NOT READY TO SIGN]

## Summary

| | |
|---|---|
| Target date | Nov 25, 2026 (staging upgrade + migrate; staging hard fork Nov 30) |
| Depends on | [126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000](../126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000/README.md) |
| Sequencing | Staging 2/4. Followed by [128-U22-staging-op-uni-replica-opcm-migrate-v1000](../128-U22-staging-op-uni-replica-opcm-migrate-v1000/README.md). Staging PAO nonce 159. |

| Chain | Chain ID | Change |
|---|---|---|
| sepolia-devnet-6 | 420130021 | v9 -> v10, SUPER_PERMISSIONED (5) kept |

## Objective

Upgrade 22 (`op-contracts/v10.0.0`) on sepolia-devnet-6: one `OPCM.upgradeSuperchain` on the devnet's own SuperchainConfig, then one `OPCM.upgrade` via `OPCMUpgradeV1000`, from the staging ProxyAdminOwner Safe `0xe934Dc97E347C6aCef74364B50125bb8689c40ff` (1-of-1). sepolia-devnet-6 is a custom-gas-token chain on permissioned proofs: it stays on SUPER_PERMISSIONED (5), and SUPER_CANNON_KONA (9) and ZK_DISPUTE_GAME (10) stay disabled. It is not migrated, as custom-gas-token chains cannot join an interop set. A separate task from sep/126 because the chain has its own SuperchainConfig.

## Open items

- [ ] `expectedValidationErrors`: pre-filled from U21 sep/123; confirm against the v10 validator in simulation.
- [ ] Calldata breakdown and state changes in VALIDATION.md.
- [ ] Re-check staging PAO nonce before signing.

## Simulation & Signing

This is a **single-safe** task, so no child-safe argument is needed.

```bash
cd src/tasks/sep/127-U22-staging-devnet-6-opcm-upgrade-v1000

just simulate-stack sep 127-U22-staging-devnet-6-opcm-upgrade-v1000

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 127-U22-staging-devnet-6-opcm-upgrade-v1000
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
