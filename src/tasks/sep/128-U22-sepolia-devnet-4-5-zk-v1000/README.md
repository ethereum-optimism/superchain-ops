# 128-U22-sepolia-devnet-4-5-zk-v1000

Status: [DRAFT, NOT READY TO SIGN]

Scaffold. ZK is activated with a single OPCM re-run (ZK on, SUPER_CANNON_KONA off, respect 10), as agreed with the proofs team.

## Summary

| | |
|---|---|
| Target date | Week of Nov 30, 2026, after the staging hard fork, with the proposer stop/restart |
| Depends on | [127-U22-sepolia-devnet-4-5-opcm-migrate-v1000](../127-U22-sepolia-devnet-4-5-opcm-migrate-v1000/README.md) and staging hard fork activation (Nov 30). |
| Sequencing | Staging 3/3. Staging PAO nonce 160. |

| Chain | Chain ID | Change |
|---|---|---|
| sepolia-devnet-4 (redeployed) | TODO | ZK (10) on, SCK (9) off, respect 10 |
| sepolia-devnet-5 (redeployed) | TODO | ZK (10) on, SCK (9) off, respect 10 |

## Objective

Second `OPCMUpgradeV1000` run on the migrated devnet-4/-5 set: registers ZK_DISPUTE_GAME (10) on the shared DisputeGameFactory, disables SUPER_CANNON_KONA (9) and sets the respected game type to 10. Same v10 OPCM as the upgrade (v10 only permits a re-run of the same OPCM address or a higher minor). Both chains must carry identical game configs.

## Open items

- [ ] OPCM address: op-contracts/v10.0.0 OPCM (`TODO_U22_OPCM_ADDRESS`), from the stable release tag and the superchain-registry standard-versions file.
- [ ] `expectedValidationErrors`: fill from the StandardValidator output once simulated.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [ ] ZK config: SP1 vkey (`kona-sp1`), max challenge/prove durations, challenger bond, init bond.
- [ ] ZK proposer and challenger config ready; stop proposer, execute, restart.
- [ ] Old challenger keeps playing in-flight SUPER_CANNON_KONA games.

## Simulation & Signing

This is a **single-safe** task, so no child-safe argument is needed.

```bash
cd src/tasks/sep/128-U22-sepolia-devnet-4-5-zk-v1000

just simulate-stack sep 128-U22-sepolia-devnet-4-5-zk-v1000

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 128-U22-sepolia-devnet-4-5-zk-v1000
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
