# 129-U22-staging-op-uni-replica-zk-v1000

Status: [DRAFT, NOT READY TO SIGN]

ZK is activated with a single OPCM re-run (ZK on, SUPER_CANNON_KONA off, respect 10), as agreed with the proofs team.

## Summary

| | |
|---|---|
| Target date | Dec 1, 2026, after the staging hard fork, with the proposer stop/restart |
| Depends on | [128-U22-staging-op-uni-replica-opcm-migrate-v1000](../128-U22-staging-op-uni-replica-opcm-migrate-v1000/README.md) and staging hard fork activation (Nov 30). |
| Sequencing | Staging 4/4. Staging PAO nonce 161. |

| Chain | Chain ID | Change |
|---|---|---|
| stg-op-replica | 420130023 | ZK (10) on, SCK (9) off, respect 10 |
| stg-uni-replica | 420130024 | ZK (10) on, SCK (9) off, respect 10 |

## Objective

Second `OPCMUpgradeV1000` run on the migrated stg-op-replica + stg-uni-replica set: registers ZK_DISPUTE_GAME (10) on the shared DisputeGameFactory, disables SUPER_CANNON_KONA (9) and sets the respected game type to 10. Same v10 OPCM as the upgrade (v10 only permits a re-run of the same OPCM address or a higher minor). Both chains must carry identical game configs.

## Open items

- [x] OPCM address: op-contracts/v10.0.0 OPCM `0x91C167C7AfBd0D0ACc0AA7e4525e90B5CCcb76A7` (`standard-versions-sepolia.toml`, same commit as v10.0.0-rc.2).
- [x] `expectedValidationErrors`: OVERRIDES-L1PAOMULTISIG, SYSCON-130 per chain, from the v10 validator in simulation.
- [x] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [x] ZK config from Proofs: 4 day max challenge duration, 3 day max prove duration, 0.1 ETH challenger bond, 0.2 ETH init bond.
- [ ] SP1 vkey: kona-sp1 v1.0.0-rc.1 super-aggregation vkey `0x0073def5ff73ea4fa3adb828fa0839943e1fbf439e669779c66dcea387d71562` (superchain-registry #1426, OP+Unichain dependency sets); confirm with Proofs it covers op-int-0/uni-int-0.
- [ ] ZK proposer and challenger config ready; stop proposer, execute, restart.
- [ ] Old challenger keeps playing in-flight SUPER_CANNON_KONA games.

## Simulation & Signing

This is a **single-safe** task, so no child-safe argument is needed.

```bash
cd src/tasks/sep/129-U22-staging-op-uni-replica-zk-v1000

just simulate-stack sep 129-U22-staging-op-uni-replica-zk-v1000

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 129-U22-staging-op-uni-replica-zk-v1000
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
