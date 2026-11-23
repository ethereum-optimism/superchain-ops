# 096-U22-op-uni-zk-v1000

Status: [DRAFT, NOT READY TO SIGN]

Scaffold. ZK is activated with a single OPCM re-run (ZK on, SUPER_CANNON_KONA off, respect 10), as agreed with the proofs team.

## Summary

| | |
|---|---|
| Target date | Right after Lagoon activation on Mainnet (Jan 11, 2027) |
| Depends on | [095-U22-op-uni-opcm-migrate-v1000](../095-U22-op-uni-opcm-migrate-v1000/README.md) and Lagoon activation on Mainnet (Jan 11). |
| Sequencing | Mainnet 3/3. Nonces L1PAO 53, FUS 89, SC 80. Any L1PAO/FUS/SC task between Dec 17 and Jan 11 shifts these. |

| Chain | Chain ID | Change |
|---|---|---|
| OP Mainnet | 10 | ZK (10) on, SCK (9) off, respect 10 |
| Unichain | 130 | ZK (10) on, SCK (9) off, respect 10 |

## Objective

Second `OPCMUpgradeV1000` run on the migrated OP Mainnet + Unichain set: registers ZK_DISPUTE_GAME (10) on the shared DisputeGameFactory, disables SUPER_CANNON_KONA (9) and sets the respected game type to 10. Must use the same v10 OPCM address as the upgrade. Both chains carry identical game configs.

## Open items

- [x] OPCM address: op-contracts/v10.0.0-rc.2 OPCM `0x7d060B2f703c7A32Bb0D3775DA2E6c4Cc0cDdd56` (superchain-registry #1424, `standard-versions-mainnet.toml`).
- [ ] `expectedValidationErrors`: fill from the StandardValidator output once simulated.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [ ] ZK config: SP1 vkey (`kona-sp1`), max challenge/prove durations, challenger bond, init bond.
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
