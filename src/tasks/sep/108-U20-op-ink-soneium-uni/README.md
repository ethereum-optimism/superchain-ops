# 108-U20-op-ink-soneium-uni

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Executes Upgrade 20 (`op-contracts/v8.0.0-rc.3`) on the four OP-governed Sepolia chains in
a single transaction from the standard Sepolia L1 ProxyAdminOwner
([`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L47),
2-of-2 of the [Foundation Upgrade Safe](../../../addresses.toml#L18) and the
[Security Council](../../../addresses.toml#L19)): one `OPCM.upgradeSuperchain` followed by
one `OPCM.upgrade` per chain, through the v8.0.0-rc.3
[OPCM `0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/validation/standard/standard-versions-sepolia.toml#L9-L25)
(version 8.0.1).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| OP Sepolia Testnet | 11155420 | CANNON_KONA (8) → SUPER_CANNON_KONA (9) | [`0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L52) |
| Ink Sepolia | 763373 | CANNON_KONA (8) → SUPER_CANNON_KONA (9) | [`0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/ink.toml#L52) |
| Soneium Testnet Minato | 1946 | CANNON_KONA (8) → SUPER_CANNON_KONA (9) | [`0x4Ca9608Fef202216bc21D543798ec854539bAAd3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/soneium-minato.toml#L52) |
| Unichain Sepolia Testnet | 1301 | CANNON_KONA (8) → SUPER_CANNON_KONA (9) | [`0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/unichain.toml#L52) |

On every chain the upgrade moves `SystemConfig` to 4.0.0 and `OptimismPortal2` to 5.8.0,
clears the CANNON (0), PERMISSIONED_CANNON (1) and CANNON_KONA (8) game implementations,
installs SUPER_PERMISSIONED (5, bondless, proposer-only) and SUPER_CANNON_KONA (9, 0.08 ETH
bond), and re-anchors the `AnchorStateRegistry` to a super root. Games created before the
upgrade keep resolving but no longer update the anchor.

`SUPER_CANNON_KONA` uses the kona-client/v1.7.0-rc.2 `cannon64-kona-interop` prestate
[`0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df`](https://github.com/ethereum-optimism/superchain-registry/blob/f4b4840352b7ce490d52ad6379ea403dfb3a37e1/validation/standard/standard-prestates.toml).
Each chain's starting anchor is a single-chain super root at a finalized L2 block, derived on
2026-09-08 with the monorepo's `op-chain-ops/cmd/check-super-root` (block, timestamp and RPC
per chain in [config.toml](./config.toml)). The anchors are part of the signed calldata and are
fixed once it is published.

> [!NOTE]
> Unichain Sepolia's `ProxyAdmin` and `DisputeGameFactory` were transferred from the Unichain
> Safe `0xd363339eE47775888Df411A163c586a8BdEA9dbf` to the standard L1PAO outside this repo;
> the transfer is on-chain. The registry pin still records the old owner, so
> [config.toml](./config.toml) pins the root safe explicitly.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/sep/108-U20-op-ink-soneium-uni

just simulate-stack sep 108-U20-op-ink-soneium-uni council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 108-U20-op-ink-soneium-uni council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per
safe, then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/sep/108-U20-op-ink-soneium-uni

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
