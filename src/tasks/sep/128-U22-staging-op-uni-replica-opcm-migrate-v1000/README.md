# 128-U22-staging-op-uni-replica-opcm-migrate-v1000

Status: [READY TO SIGN]

## Summary

| | |
|---|---|
| Target date | Nov 25, 2026, right after the upgrade |
| Depends on | [126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000](../126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000/README.md) and [127-U22-staging-devnet-6-opcm-upgrade-v1000](../127-U22-staging-devnet-6-opcm-upgrade-v1000/README.md) (migrate requires every chain on the v10 OPCM). |
| Sequencing | Staging 3/4. Followed by [129-U22-staging-op-uni-replica-zk-v1000](../129-U22-staging-op-uni-replica-zk-v1000/README.md). Staging PAO nonce 160. |

| Chain | Chain ID | Change |
|---|---|---|
| stg-op-replica | 420130023 | INTEROP, shared dispute contracts |
| stg-uni-replica | 420130024 | INTEROP, shared dispute contracts |

## Objective

`OPCMv2.migrate` (`OPCMMigrateV1000`) for stg-op-replica and stg-uni-replica as one interop dependency set: deploys a shared ETHLockbox, DisputeGameFactory and AnchorStateRegistry, makes op-int-0's DelayedWETH the shared one, moves the ETH into the shared lockbox, enables INTEROP and registers SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9) on the shared factory, respecting 9. One-way, invalidates prior withdrawal proofs.

## Open items

- [x] OPCM address: op-contracts/v10.0.0 OPCM `0x91C167C7AfBd0D0ACc0AA7e4525e90B5CCcb76A7` (`standard-versions-sepolia.toml`, same commit as v10.0.0-rc.2).
- [x] `expectedValidationErrors`: MIG-SLOCKBOX-40, MIG-CHAIN-0-130, MIG-CHAIN-1-130 (migration) and OVERRIDES-L1PAOMULTISIG, SYSCON-130 per chain, from the v10 validators in simulation.
- [x] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.
- [x] Replica contract addresses: op-int-0 and uni-int-0 in the superchain-registry (`sepolia-devnets`, #1420).
- [x] Dependency-set kona interop prestate: `0x034589520fac03115a1d2f1dc8ae3632c15593d4b084a6bbb985966f20fed93d`, kona-client v1.10.0-rc.1 (superchain-registry #1425), checked against the registry.
- [x] Shared SUPER_PERMISSIONED proposer: op-int-0's proposer `0x0595c28b885f65Ce70d65e1A1593ac77e1F2d8Ba` (superchain-registry `addresses.json`, live game 5 args, k8s-netchef-stg op-signer). uni-int-0's proposer `0xf2CB80F7E9C4b2427f3c60b2254af6B8B56122d6` must be stopped after execution.
- [x] Starting anchor: super root `0xf47562c855e09d6c10a7bda89c8c0a13dbacf6fe75168ee207ff52bf6069e9ce` at timestamp `1795551692` (op-int-0 block 258340, uni-int-0 block 514376, both finalized), computed from the L2 EL RPCs as `keccak256(0x01 ‖ be64(ts) ‖ chainId ‖ outputRoot …)`. Recomputed from the L2 EL RPCs on 2026-11-25 (match). Confirm the supernode has safe-head history back to this timestamp before signing.
- [ ] Supernode, challenger and proposer cut-over ready (infra, no ops task).

## Simulation & Signing

This is a **single-safe** task, so no child-safe argument is needed.

```bash
cd src/tasks/sep/128-U22-staging-op-uni-replica-opcm-migrate-v1000

just simulate-stack sep 128-U22-staging-op-uni-replica-opcm-migrate-v1000

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 128-U22-staging-op-uni-replica-opcm-migrate-v1000
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
