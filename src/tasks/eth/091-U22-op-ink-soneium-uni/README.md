# 091-U22-op-ink-soneium-uni

Status: [DRAFT, NOT READY TO SIGN]

Scaffold. Every U22 release input is a placeholder.

## Summary

| | |
|---|---|
| Target date | Dec 15-17, 2026 (before the end-of-year pause; signatures gathered before the break) |
| Depends on | U21 (eth/084, executed); eth/085-087 and eth/090 for nonces. |
| Sequencing | Mainnet 1/3. Followed by [092-U22-op-uni-opcm-migrate-v1000](../092-U22-op-uni-opcm-migrate-v1000/README.md). Nonces L1PAO 51, FUS 84, SC 78. Nonces assume eth/085-087 and eth/090 (#1639) execute first. |

| Chain | Chain ID | Change |
|---|---|---|
| OP Mainnet | 10 | v9 -> v10, SUPER_CANNON_KONA (9) kept |
| Ink | 57073 | v9 -> v10, SUPER_CANNON_KONA (9) kept |
| Soneium | 1868 | v9 -> v10, SUPER_PERMISSIONED (5) kept |
| Unichain | 130 | v9 -> v10, SUPER_CANNON_KONA (9) kept |

## Objective

Upgrade 22 (`op-contracts/v10.0.0`) on the four OP-governed Mainnet chains from the Mainnet L1PAO `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (FoundationUpgradeSafe + SecurityCouncil): one `OPCM.upgradeSuperchain`, then one `OPCM.upgrade` per chain via `OPCMUpgradeV1000`. OP Mainnet, Ink and Unichain keep SUPER_CANNON_KONA (9); Soneium stays permissioned on SUPER_PERMISSIONED (5). Only OP Mainnet and Unichain migrate afterwards.

## Open items

- [ ] OPCM address: op-contracts/v10.0.0 OPCM (`TODO_U22_OPCM_ADDRESS`), from the stable release tag and the superchain-registry standard-versions file.
- [ ] `expectedValidationErrors`: fill from the StandardValidator output once simulated.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [ ] U22 SUPER_CANNON_KONA prestate (`TODO_U22_KONA_INTEROP_PRESTATE`), from standard-prestates.toml.
- [ ] Re-check `storageCodeExceptions` (Unichain / Soneium slot 0x6c) against the v10 simulation.
- [ ] Re-pin nonces if eth/085-087 or eth/090 slip, are cancelled or a private task lands first.
- [ ] Governance kickoff ~Dec 5.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/091-U22-op-ink-soneium-uni

just simulate-stack eth 091-U22-op-ink-soneium-uni council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 091-U22-op-ink-soneium-uni council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
