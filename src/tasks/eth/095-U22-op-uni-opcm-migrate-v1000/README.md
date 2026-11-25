# 095-U22-op-uni-opcm-migrate-v1000

Status: [DRAFT, NOT READY TO SIGN]

## Summary

| | |
|---|---|
| Target date | Dec 14, 2026, right after the upgrade |
| Depends on | [094-U22-op-ink-soneium-uni](../094-U22-op-ink-soneium-uni/README.md) (migrate requires every chain on the v10 OPCM). |
| Sequencing | Mainnet 2/3. Followed by [096-U22-op-uni-zk-v1000](../096-U22-op-uni-zk-v1000/README.md). Nonces L1PAO 52, FUS 88, SC 79. |

| Chain | Chain ID | Change |
|---|---|---|
| OP Mainnet | 10 | INTEROP, shared dispute contracts |
| Unichain | 130 | INTEROP, shared dispute contracts |

## Objective

`OPCMv2.migrate` (`OPCMMigrateV1000`) for OP Mainnet and Unichain as one interop dependency set: deploys a shared ETHLockbox, DisputeGameFactory, AnchorStateRegistry and DelayedWETH, moves both chains' ETH into the shared lockbox, enables INTEROP and registers SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9) on the shared factory, respecting 9. One-way, invalidates prior withdrawal proofs. Ink and Soneium do not migrate.

## Open items

- [x] OPCM address: op-contracts/v10.0.0-rc.2 OPCM `0x7d060B2f703c7A32Bb0D3775DA2E6c4Cc0cDdd56` (superchain-registry #1424, `standard-versions-mainnet.toml`).
- [x] `expectedValidationErrors` from the v10 validator in simulation.
- [x] Domain/message hashes in VALIDATION.md.
- [ ] Calldata breakdown and state changes in VALIDATION.md.
- [x] Dependency-set kona interop prestate `0x034589520fac03115a1d2f1dc8ae3632c15593d4b084a6bbb985966f20fed93d` (kona-client v1.10.0-rc.1, superchain-registry #1425).
- [x] Shared SUPER_PERMISSIONED proposer: the OP chain's current proposer (see config.toml).
- [ ] Starting anchor: super root at 1795622400 (2026-11-25 16:00 UTC) in config.toml; refresh close to governance kickoff (~Dec 5); confirm proof/blob history retention covers the gap to execution.
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
