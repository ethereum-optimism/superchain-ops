# 096-U22-op-uni-zk-v1000

Status: [DRAFT, NOT READY TO SIGN]

ZK is activated with a single OPCM re-run (ZK on, SUPER_CANNON_KONA off, respect 10), as agreed with the proofs team.

## Summary

| | |
|---|---|
| Target date | Jan 14, 2027, after Lagoon activation on Mainnet (Jan 11) |
| Depends on | [095-U22-op-uni-opcm-migrate-v1000](../095-U22-op-uni-opcm-migrate-v1000/README.md) and Lagoon activation on Mainnet (Jan 11). |
| Sequencing | Mainnet 3/3. Nonces L1PAO 53, FUS 89, SC 80. Any L1PAO/FUS/SC task between Dec 14 and Jan 14 shifts these. |

| Chain | Chain ID | Change |
|---|---|---|
| OP Mainnet | 10 | ZK (10) on, SCK (9) off, respect 10 |
| Unichain | 130 | ZK (10) on, SCK (9) off, respect 10 |

## Objective

Second `OPCMUpgradeV1000` run on the migrated OP Mainnet + Unichain set: registers ZK_DISPUTE_GAME (10) on the shared DisputeGameFactory, disables SUPER_CANNON_KONA (9) and sets the respected game type to 10. Must use the same v10 OPCM address as the upgrade. Both chains carry identical game configs.

## Open items

- [x] OPCM address: op-contracts/v10.0.0-rc.2 OPCM `0x7d060B2f703c7A32Bb0D3775DA2E6c4Cc0cDdd56` (superchain-registry #1424, `standard-versions-mainnet.toml`).
- [x] `expectedValidationErrors` from the v10 validator in simulation.
- [x] Domain/message hashes in VALIDATION.md.
- [ ] Calldata breakdown and state changes in VALIDATION.md.
- [x] ZK config: vkey `0x0073def5ff73ea4fa3adb828fa0839943e1fbf439e669779c66dcea387d71562` (kona-sp1 v1.0.0-rc.1, superchain-registry #1426), 4 day max challenge duration, 3 day max prove duration, 0.1 ETH challenger bond, 0.2 ETH init bond.
- [ ] ZK proposer and challenger config ready; stop proposer, execute, restart.
- [ ] Old challenger keeps playing in-flight SUPER_CANNON_KONA games.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/096-U22-op-uni-zk-v1000

just simulate-stack eth 096-U22-op-uni-zk-v1000 council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 096-U22-op-uni-zk-v1000 council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
