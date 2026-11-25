# 094-U22-op-ink-soneium-uni

Status: [DRAFT, NOT READY TO SIGN]

## Summary

| | |
|---|---|
| Target date | Dec 14, 2026 (signatures Dec 10-11, before the end-of-year pause) |
| Depends on | U21 (eth/084, executed). |
| Sequencing | Mainnet 1/3. Followed by [095-U22-op-uni-opcm-migrate-v1000](../095-U22-op-uni-opcm-migrate-v1000/README.md). Nonces L1PAO 51, FUS 87, SC 78. |

| Chain | Chain ID | Change |
|---|---|---|
| OP Mainnet | 10 | v9 -> v10, SUPER_CANNON_KONA (9) kept |
| Ink | 57073 | v9 -> v10, SUPER_CANNON_KONA (9) kept |
| Soneium | 1868 | v9 -> v10, SUPER_PERMISSIONED (5) kept |
| Unichain | 130 | v9 -> v10, SUPER_CANNON_KONA (9) kept |

## Objective

Upgrade 22 (`op-contracts/v10.0.0`) on the four OP-governed Mainnet chains from the Mainnet L1PAO `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (FoundationUpgradeSafe + SecurityCouncil): one `OPCM.upgradeSuperchain`, then one `OPCM.upgrade` per chain via `OPCMUpgradeV1000`. OP Mainnet, Ink and Unichain keep SUPER_CANNON_KONA (9); Soneium stays permissioned on SUPER_PERMISSIONED (5). Only OP Mainnet and Unichain migrate afterwards.

## Open items

- [x] OPCM address: op-contracts/v10.0.0-rc.2 OPCM `0x7d060B2f703c7A32Bb0D3775DA2E6c4Cc0cDdd56` (superchain-registry #1424, `standard-versions-mainnet.toml`).
- [x] `expectedValidationErrors` from the v10 validator in simulation.
- [x] Domain/message hashes in VALIDATION.md.
- [ ] Calldata breakdown and state changes in VALIDATION.md.
- [x] SUPER_CANNON_KONA prestate `0x034589520fac03115a1d2f1dc8ae3632c15593d4b084a6bbb985966f20fed93d` (kona-client v1.10.0-rc.1, superchain-registry #1425). Ink also gets ZK_DISPUTE_GAME (10), not respected, with the ZK config of eth/096. Soneium expects `DF-60` (permissioned only).
- [ ] Re-check `storageCodeExceptions` (Unichain / Soneium slot 0x6c) against the v10 simulation.
- [ ] Re-pin nonces if another L1PAO/FUS/SC task lands first.
- [ ] Governance kickoff ~Dec 5.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/094-U22-op-ink-soneium-uni

just simulate-stack eth 094-U22-op-ink-soneium-uni council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 094-U22-op-ink-soneium-uni council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
