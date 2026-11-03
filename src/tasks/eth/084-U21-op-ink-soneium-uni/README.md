# 084-U21-op-ink-soneium-uni

Status: DRAFT, NOT READY TO SIGN

## Objective

Executes Upgrade 21 (`op-contracts/v9.0.0`) on the four OP-governed Mainnet chains in a
single transaction from the standard Mainnet L1 ProxyAdminOwner
([`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L47),
2-of-2 of the [Foundation Upgrade Safe](../../../addresses.toml#L6) and the
[Security Council](../../../addresses.toml#L7)): one `OPCM.upgradeSuperchain` followed by
one `OPCM.upgrade` per chain, through the v9.0.0-rc.1
[OPCM `0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f`](https://github.com/ethereum-optimism/superchain-registry/blob/41553edca76a4d67d7be0b57f857ffc978295153/validation/standard/standard-versions-mainnet.toml)
(version 9.0.3).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| OP Mainnet | 10 | SUPER_CANNON_KONA (9), unchanged | [`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L52) |
| Ink | 57073 | SUPER_CANNON_KONA (9), unchanged | [`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/ink.toml#L52) |
| Soneium | 1868 | SUPER_PERMISSIONED (5), unchanged | [`0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/soneium.toml#L52) |
| Unichain | 130 | SUPER_CANNON_KONA (9), unchanged | [`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/unichain.toml#L52) |

On every chain the upgrade moves `SystemConfig` to 4.3.0, `OptimismPortal2` to 6.1.0,
`L1CrossDomainMessenger` to 2.13.0, `AnchorStateRegistry` to 4.0.0, `DelayedWETH` to 2.0.0 and
`ETHLockbox` to 2.0.0, and the shared `SuperchainConfig` to 2.5.0. It re-registers
SUPER_PERMISSIONED (5, bondless, proposer-only) on every chain and SUPER_CANNON_KONA (9,
0.08 ETH bond) with the U21 prestate on OP Mainnet, Ink and Unichain, and carries each chain's
current super-root anchor forward. Soneium has no SUPER_CANNON_KONA implementation to carry
over, so it stays permissioned on SUPER_PERMISSIONED. All four chains already have an
`ETHLockbox` wired to their portal, so no ETH moves and the chain-specific pause identifier is
unchanged.

`SUPER_CANNON_KONA` uses the kona-client/v1.9.0 `cannon64-kona-interop` prestate
[`0x03b985a286da46ca88c0a965a53942daade9ffe1ae6b854a8f2d083df1cfaf59`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml),
the prestate listed on the [Upgrade 21 notice page](https://docs.optimism.io/notices/upgrade-21).

> [!NOTE]
> Unichain's `ProxyAdmin` and `DisputeGameFactory` are owned by the standard L1PAO on-chain
> (eth/069); the registry pin still records the old owner, so [config.toml](./config.toml)
> pins the root safe explicitly, as eth/071 did.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/084-U21-op-ink-soneium-uni

just simulate-stack eth 084-U21-op-ink-soneium-uni council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 084-U21-op-ink-soneium-uni council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
