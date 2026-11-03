# 115-U21-op-ink-soneium-uni

Status: DRAFT, NOT READY TO SIGN

## Objective

Executes Upgrade 21 (`op-contracts/v9.0.0`) on the four OP-governed Sepolia chains in a
single transaction from the standard Sepolia L1 ProxyAdminOwner
([`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L47),
2-of-2 of the [Foundation Upgrade Safe](../../../addresses.toml#L18) and the
[Security Council](../../../addresses.toml#L19)): one `OPCM.upgradeSuperchain` followed by
one `OPCM.upgrade` per chain, through the v9.0.0-rc.1
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://github.com/ethereum-optimism/superchain-registry/blob/41553edca76a4d67d7be0b57f857ffc978295153/validation/standard/standard-versions-sepolia.toml)
(version 9.0.3).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| OP Sepolia Testnet | 11155420 | SUPER_CANNON_KONA (9), unchanged | [`0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L52) |
| Ink Sepolia | 763373 | SUPER_CANNON_KONA (9), unchanged | [`0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/ink.toml#L52) |
| Soneium Testnet Minato | 1946 | SUPER_CANNON_KONA (9), unchanged | [`0x4Ca9608Fef202216bc21D543798ec854539bAAd3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/soneium-minato.toml#L52) |
| Unichain Sepolia Testnet | 1301 | SUPER_CANNON_KONA (9), unchanged | [`0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/unichain.toml#L52) |

On every chain the upgrade moves `SystemConfig` to 4.3.0, `OptimismPortal2` to 6.1.0,
`L1CrossDomainMessenger` to 2.13.0, `AnchorStateRegistry` to 4.0.0, `DelayedWETH` to 2.0.0 and
`ETHLockbox` to 2.0.0, and the shared `SuperchainConfig` to 2.5.0. It re-registers
SUPER_PERMISSIONED (5, bondless, proposer-only) and SUPER_CANNON_KONA (9, 0.08 ETH bond) with
the U21 prestate and carries each chain's current super-root anchor forward. All four chains
already have an `ETHLockbox` wired to their portal, so no ETH moves and the chain-specific
pause identifier is unchanged.

`SUPER_CANNON_KONA` uses the kona-client/v1.9.0 `cannon64-kona-interop` prestate
[`0x03b985a286da46ca88c0a965a53942daade9ffe1ae6b854a8f2d083df1cfaf59`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml),
the prestate listed on the [Upgrade 21 notice page](https://docs.optimism.io/notices/upgrade-21).

> [!NOTE]
> Unichain Sepolia's `ProxyAdmin` and `DisputeGameFactory` are owned by the standard L1PAO
> on-chain; the registry pin still records the old owner, so [config.toml](./config.toml)
> pins the root safe explicitly, as sep/108 did.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/sep/115-U21-op-ink-soneium-uni

just simulate-stack sep 115-U21-op-ink-soneium-uni council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 115-U21-op-ink-soneium-uni council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
