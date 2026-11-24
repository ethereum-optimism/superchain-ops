# 126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000

Status: [DRAFT, NOT READY TO SIGN]

Scaffold. The replicas' contract addresses and every U22 release input are placeholders.

## Summary

| | |
|---|---|
| Target date | Nov 25, 2026 (staging upgrade + migrate; staging hard fork Nov 30) |
| Depends on | Deploy of stg-op-replica / stg-uni-replica on op-contracts/v9 through the devnet v9.0.3 OPCM `0x49Fbb5dc6Af181bD91686a6520C16236040A20B1` (devnets-private #2723, #2724). |
| Sequencing | Staging 1/4. Followed by [127-U22-staging-devnet-6-opcm-upgrade-v1000](../127-U22-staging-devnet-6-opcm-upgrade-v1000/README.md). Staging PAO nonce 158. |

| Chain | Chain ID | Change |
|---|---|---|
| sepolia-devnet-2 | 420130015 | v9 -> v10, SUPER_CANNON_KONA (9) kept |
| sepolia-devnet-3 | 420130018 | v9 -> v10, SUPER_PERMISSIONED (5) kept |
| stg-op-replica | 420130023 | v9 -> v10, SUPER_CANNON_KONA (9) kept |
| stg-uni-replica | 420130024 | v9 -> v10, SUPER_CANNON_KONA (9) kept |

## Objective

Upgrade 22 (`op-contracts/v10.0.0`) on the four OP Labs staging networks: one `OPCM.upgradeSuperchain`, then one `OPCM.upgrade` per chain via `OPCMUpgradeV1000`, from the staging ProxyAdminOwner Safe `0xe934Dc97E347C6aCef74364B50125bb8689c40ff` (1-of-1). Games and respected game types are kept: devnet-2 (Ink-like) and the redeployed OP and Unichain replicas (stg-op-replica, stg-uni-replica; they replace sepolia-devnet-4/-5) stay on SUPER_CANNON_KONA (9), devnet-3 (Soneium-like) stays on SUPER_PERMISSIONED (5).

## Open items

- [x] OPCM address: op-contracts/v10.0.0-rc.2 OPCM `0x91C167C7AfBd0D0ACc0AA7e4525e90B5CCcb76A7` (superchain-registry #1424, `standard-versions-sepolia.toml`).
- [ ] `expectedValidationErrors`: fill from the StandardValidator output once simulated.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [x] Replica contract addresses: op-int-0 and uni-int-0 in the superchain-registry (`sepolia-devnets`, #1420). Confirm they use the devnet SuperchainConfig `0x289d2A1b1AE6E0470D8B72E53B6E3f485f251DBb` and the staging PAO (the v9 OPCM they deploy with is bound to both).
- [ ] Uses the same official Sepolia v10 OPCM as sep/130-132, not a devnet-bound one, as U21 did. Expected validator errors (staging Safe, devnet SuperchainConfig, devnet challenger) are pre-filled from sep/122 and sep/125; confirm them against the v10 validator in simulation.
- [ ] SUPER_CANNON_KONA prestate: `0x034589520fac03115a1d2f1dc8ae3632c15593d4b084a6bbb985966f20fed93d` (kona-client-int built from optimism develop `24623f2c`, embeds devnet-2/3, op-int-0, uni-int-0 and Lagoon). Not in the registry yet, so devnet-2 and the replicas skip the registry prestate check; swap for the U22 kona-client release prestate once tagged.
- [ ] Re-check staging PAO nonce (158 on 2026-11-18) before signing.

## Simulation & Signing

This is a **single-safe** task, so no child-safe argument is needed.

```bash
cd src/tasks/sep/126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000

just simulate-stack sep 126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
