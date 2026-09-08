# 071-U20-op-ink-soneium-uni

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Executes Upgrade 20 (`op-contracts/v8.0.0-rc.3`) on the four OP-governed mainnet chains in a
single transaction from the standard Mainnet L1 ProxyAdminOwner
([`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L46),
2-of-2 of the [Foundation Upgrade Safe](../../../addresses.toml#L6) and the
[Security Council](../../../addresses.toml#L7)): one `OPCM.upgradeSuperchain` followed by
one `OPCM.upgrade` per chain, through the v8.0.0-rc.3
[OPCM `0x1951828ce913dc4383a8a1695695d537a11d896a`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/validation/standard/standard-versions-mainnet.toml#L9-L25)
(version 8.0.1).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| OP Mainnet | 10 | CANNON_KONA (8) → SUPER_CANNON_KONA (9) | [`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L51) |
| Ink | 57073 | CANNON_KONA (8) → SUPER_CANNON_KONA (9) | [`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/ink.toml#L51) |
| Soneium | 1868 | PERMISSIONED_CANNON (1) → SUPER_PERMISSIONED (5) | [`0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/soneium.toml#L51) |
| Unichain | 130 | CANNON_KONA (8) → SUPER_CANNON_KONA (9) | [`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/unichain.toml#L51) |

On every chain the upgrade moves `SystemConfig` to 4.0.0 and `OptimismPortal2` to 5.8.0,
clears the CANNON (0), PERMISSIONED_CANNON (1) and CANNON_KONA (8) game implementations,
installs SUPER_PERMISSIONED (5, bondless, proposer-only) and re-anchors the
`AnchorStateRegistry` to a super root. OP Mainnet, Ink and Unichain additionally install
SUPER_CANNON_KONA (9, 0.08 ETH bond) and make it the respected game type; Soneium stayed
permissioned through U19 and has no CANNON_KONA implementation to carry over, so it moves to
SUPER_PERMISSIONED. Games created before the upgrade keep resolving but no longer update the
anchor.

`SUPER_CANNON_KONA` uses the kona-client/v1.7.0-rc.2 `cannon64-kona-interop` prestate
[`0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df`](https://github.com/ethereum-optimism/superchain-registry/blob/f4b4840352b7ce490d52ad6379ea403dfb3a37e1/validation/standard/standard-prestates.toml).
Each chain's starting anchor is a single-chain super root at a finalized L2 block, derived on
2026-09-08 with the monorepo's `op-chain-ops/cmd/check-super-root` (block, timestamp and RPC
per chain in [config.toml](./config.toml)). The anchors are part of the signed calldata and are
fixed once the governance post publishes it.

> [!IMPORTANT]
> This task is sequenced after `067-mmzd-l1-ownership-transfers`, `068-mmzd-l2pao-transfer`,
> `069-unichain-l1-ownership-transfers` and `070-unichain-l2pao-transfer`; the nonce pins in
> [config.toml](./config.toml) assume all four have executed. `eth/069` MUST execute before this
> task: it hands Unichain's `ProxyAdmin` and `DisputeGameFactory` to the L1PAO, which this
> upgrade requires. Simulation reproduces that state through state overrides.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/071-U20-op-ink-soneium-uni

just simulate-stack eth 071-U20-op-ink-soneium-uni council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 071-U20-op-ink-soneium-uni council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata
breakdown, the expected state changes, the facilitator steps and the post-execution checks.
