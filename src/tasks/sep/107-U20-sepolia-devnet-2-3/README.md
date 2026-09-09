# 107-U20-sepolia-devnet-2-3

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x8e8ed3d668f06a1430db793eff681849c837597ae5aa6358009d57c0a2bc61b4)

## Objective

Executes Upgrade 20 (`op-contracts/v8.0.0-rc.3`) on the two OP Labs Sepolia devnets in a single
transaction from the shared devnet ProxyAdminOwner Safe
([`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia-devnet-2/sepolia-devnet-2.toml#L49),
1-of-1): one `OPCM.upgradeSuperchain` followed by one `OPCM.upgrade` per chain, through the
v8.0.0-rc.3
[OPCM `0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/validation/standard/standard-versions-sepolia.toml#L9-L25)
(version 8.0.1).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| sepolia-devnet-2 | 420130015 | CANNON_KONA (8) → SUPER_CANNON_KONA (9) | [`0x5F91Ea5EEA70E505b457A442Dc7A8e5D9641b937`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia-devnet-2/sepolia-devnet-2.toml#L54) |
| sepolia-devnet-3 | 420130018 | PERMISSIONED_CANNON (1) → SUPER_PERMISSIONED (5) | [`0x66dac055c7cD3B3a043760521dCa840cB3E8F3FF`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia-devnet-3/sepolia-devnet-3.toml#L54) |

On both chains the upgrade moves `SystemConfig` to 4.0.0 and `OptimismPortal2` to 5.8.0,
clears the CANNON (0), PERMISSIONED_CANNON (1) and CANNON_KONA (8) game implementations,
installs SUPER_PERMISSIONED (5, bondless, proposer-only) and re-anchors the
`AnchorStateRegistry` to a super root. sepolia-devnet-2 additionally installs
SUPER_CANNON_KONA (9, 0.08 ETH bond) and makes it the respected game type; sepolia-devnet-3
has no CANNON_KONA implementation to carry over, so it stays permissioned on
SUPER_PERMISSIONED. Games created before the upgrade keep resolving but no longer update the
anchor.

`SUPER_CANNON_KONA` on sepolia-devnet-2 uses the kona-client/v1.7.0-rc.2 `cannon64-kona-interop`
prestate
[`0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df`](https://github.com/ethereum-optimism/superchain-registry/blob/f4b4840352b7ce490d52ad6379ea403dfb3a37e1/validation/standard/standard-prestates.toml);
sepolia-devnet-2 is embedded in that kona release's registry snapshot. Each chain's starting
anchor is a single-chain super root at a finalized L2 block, derived on 2026-09-08 with the
monorepo's `op-chain-ops/cmd/check-super-root` (block, timestamp and RPC per chain in
[config.toml](./config.toml)). The anchors are part of the signed calldata and are fixed once
it is published.


## Simulation & Signing

This is a **single-safe** task: the devnet ProxyAdminOwner is a 1-of-1 Safe, so no child-safe
argument is needed.

```bash
cd src/tasks/sep/107-U20-sepolia-devnet-2-3

just simulate-stack sep 107-U20-sepolia-devnet-2-3

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 107-U20-sepolia-devnet-2-3
```

## Execution

For facilitators, once the signature has been collected. Run the pre-execution check in
[VALIDATION.md](./VALIDATION.md) first. The safe is 1-of-1; `just execute` refuses to run
without `SIGNATURES`.

```bash
cd src/tasks/sep/107-U20-sepolia-devnet-2-3

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hash, the signer
checklist, the calldata breakdown, the pre-execution check, the expected state changes and
the post-execution checks.
