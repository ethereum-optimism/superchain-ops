# 131-U22-op-uni-zk-v1000

Status: [DRAFT, NOT READY TO SIGN]

Scaffold. Path B (single OPCM re-run) chosen for now; may move to Path A (register, then Guardian `setRespectedGameType`).

## Summary

| | |
|---|---|
| Target date | Dec 10, 2026, after Lagoon activation on Sepolia |
| Depends on | [130-U22-op-uni-opcm-migrate-v1000](../130-U22-op-uni-opcm-migrate-v1000/README.md) and Lagoon activation on Sepolia (Dec 10). |
| Sequencing | Sepolia 3/3. Nonces L1PAO 64, FUS 88, SC 78. |

| Chain | Chain ID | Change |
|---|---|---|
| OP Sepolia Testnet | 11155420 | ZK (10) on, SCK (9) off, respect 10 |
| Unichain Sepolia Testnet | 1301 | ZK (10) on, SCK (9) off, respect 10 |

## Objective

Second `OPCMUpgradeV1000` run on the migrated OP Sepolia + Unichain Sepolia set: registers ZK_DISPUTE_GAME (10) on the shared DisputeGameFactory, disables SUPER_CANNON_KONA (9) and sets the respected game type to 10. Must use the same v10 OPCM address as the upgrade. Both chains carry identical game configs.

## Open items

- [ ] OPCM address: op-contracts/v10.0.0 OPCM (`TODO_U22_OPCM_ADDRESS`), from the stable release tag and the superchain-registry standard-versions file.
- [ ] `expectedValidationErrors`: fill from the StandardValidator output once simulated.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [ ] ZK config: SP1 vkey (`kona-sp1`), max challenge/prove durations, challenger bond, init bond.
- [ ] Confirm Path B with proofs (vs Path A).
- [ ] ZK proposer and challenger config ready; stop proposer, execute, restart.
- [ ] Old challenger keeps playing in-flight SUPER_CANNON_KONA games.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/sep/131-U22-op-uni-zk-v1000

just simulate-stack sep 131-U22-op-uni-zk-v1000 council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 131-U22-op-uni-zk-v1000 council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
