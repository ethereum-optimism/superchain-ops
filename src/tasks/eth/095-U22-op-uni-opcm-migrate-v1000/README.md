# 095-U22-op-uni-opcm-migrate-v1000

Status: [DRAFT, NOT READY TO SIGN]

Scaffold. Every U22 release input is a placeholder.

## Summary

| | |
|---|---|
| Target date | Same day as the upgrade (Dec 15-17, 2026), right after it |
| Depends on | [094-U22-op-ink-soneium-uni](../094-U22-op-ink-soneium-uni/README.md) (migrate requires every chain on the v10 OPCM). |
| Sequencing | Mainnet 2/3. Followed by [096-U22-op-uni-zk-v1000](../096-U22-op-uni-zk-v1000/README.md). Nonces L1PAO 52, FUS 88, SC 79. |

| Chain | Chain ID | Change |
|---|---|---|
| OP Mainnet | 10 | INTEROP, shared dispute contracts |
| Unichain | 130 | INTEROP, shared dispute contracts |

## Objective

`OPCMv2.migrate` (`OPCMMigrateV1000`) for OP Mainnet and Unichain as one interop dependency set: deploys a shared ETHLockbox, DisputeGameFactory, AnchorStateRegistry and DelayedWETH, moves both chains' ETH into the shared lockbox, enables INTEROP and registers SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9) on the shared factory, respecting 9. One-way, invalidates prior withdrawal proofs. Ink and Soneium do not migrate.

## Open items

- [ ] OPCM address: op-contracts/v10.0.0 OPCM (`TODO_U22_OPCM_ADDRESS`), from the stable release tag and the superchain-registry standard-versions file.
- [ ] `expectedValidationErrors`: fill from the StandardValidator output once simulated.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [ ] Dependency-set kona interop prestate embedding OP Mainnet + Unichain.
- [ ] Shared SUPER_PERMISSIONED proposer.
- [ ] Starting anchor (super root + L2 sequence number), set close to governance kickoff (~Dec 5); confirm proof/blob history retention covers the gap to execution.
- [ ] Gas of the single atomic `migrate()` call (open question on #1626).
- [ ] Supernode with OP Mainnet + Unichain, challenger/proposer/dispute-mon/monitoring cut-over ready (infra, no ops task).

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/095-U22-op-uni-opcm-migrate-v1000

just simulate-stack eth 095-U22-op-uni-opcm-migrate-v1000 council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 095-U22-op-uni-opcm-migrate-v1000 council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
