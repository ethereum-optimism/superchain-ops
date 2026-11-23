# 129-U22-op-ink-soneium-uni

Status: [DRAFT, NOT READY TO SIGN]

Scaffold. Every U22 release input is a placeholder.

## Summary

| | |
|---|---|
| Target date | Dec 8, 2026 |
| Depends on | U21 (sep/115, executed). OPCM v10 deployed on Sepolia. |
| Sequencing | Sepolia 1/3. Followed by [130-U22-op-uni-opcm-migrate-v1000](../130-U22-op-uni-opcm-migrate-v1000/README.md). Nonces L1PAO 62, FUS 86, SC 76. |

| Chain | Chain ID | Change |
|---|---|---|
| OP Sepolia Testnet | 11155420 | v9 -> v10, SUPER_CANNON_KONA (9) kept |
| Ink Sepolia | 763373 | v9 -> v10, SUPER_CANNON_KONA (9) kept |
| Soneium Testnet Minato | 1946 | v9 -> v10, SUPER_CANNON_KONA (9) kept |
| Unichain Sepolia Testnet | 1301 | v9 -> v10, SUPER_CANNON_KONA (9) kept |

## Objective

Upgrade 22 (`op-contracts/v10.0.0`) on the four OP-governed Sepolia chains from the Sepolia L1PAO `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (FoundationUpgradeSafe + SecurityCouncil): one `OPCM.upgradeSuperchain`, then one `OPCM.upgrade` per chain via `OPCMUpgradeV1000`. Every chain keeps SUPER_CANNON_KONA (9) as the respected game type, its anchor, delays and ETHLockbox. Only OP Sepolia and Unichain Sepolia migrate afterwards.

## Open items

- [x] OPCM address: op-contracts/v10.0.0-rc.2 OPCM `0x91C167C7AfBd0D0ACc0AA7e4525e90B5CCcb76A7` (superchain-registry #1424, `standard-versions-sepolia.toml`).
- [ ] `expectedValidationErrors`: fill from the StandardValidator output once simulated.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [ ] U22 SUPER_CANNON_KONA prestate (`TODO_U22_KONA_INTEROP_PRESTATE`), from standard-prestates.toml.
- [ ] Re-check `storageCodeExceptions` (Unichain Sepolia / Minato slot 0x6c) against the v10 simulation.
- [ ] Re-check Sepolia nonces (L1PAO 62, FUS 86, SC 76 on 2026-11-18) before signing.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/sep/129-U22-op-ink-soneium-uni

just simulate-stack sep 129-U22-op-ink-soneium-uni council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 129-U22-op-ink-soneium-uni council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
