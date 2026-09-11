# 108-U20-platforms-1

Status: [EXECUTED]

## Block + TX Hash
Sepolia Block: `11683558`
TX Hash      : `0xaa837c9a7737917c52855cd9f0de899c1ab4d25c4d85eda8d4fca9f5422bc2c4`

## Objective

Executes Upgrade 20 (`op-contracts/v8.0.0-rc.3`) on the platforms-1 devnet from the shared devnet
ProxyAdminOwner Safe [`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`](https://sepolia.etherscan.io/address/0xe934Dc97E347C6aCef74364B50125bb8689c40ff)
(1-of-1) through the v8.0.0-rc.3
[OPCM `0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca`](https://sepolia.etherscan.io/address/0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca)
(version 8.0.1).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| platforms-1 | 420130013 | CANNON_KONA (8) → SUPER_CANNON_KONA (9) | [`0x7464fAf3d39eff216f8d712A4195A2618a4Ef983`](https://sepolia.etherscan.io/address/0x7464fAf3d39eff216f8d712A4195A2618a4Ef983) |

The upgrade clears the CANNON (0), PERMISSIONED_CANNON (1) and CANNON_KONA (8) game
implementations, installs SUPER_PERMISSIONED (5, bondless, proposer-only) and
SUPER_CANNON_KONA (9), makes SUPER_CANNON_KONA the respected game type, and re-anchors the
`AnchorStateRegistry` to a super root.

State before this task (read on-chain 2026-09-10):

| Contract | Version |
|---|---|
| SystemConfig | 3.14.2 |
| OptimismPortal2 | 5.6.1 |
| DisputeGameFactory | 1.6.1 |
| AnchorStateRegistry | 3.9.0 |

`DisputeGameFactory.gameImpls`: 1 → `0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e`,
8 → `0x2DDA3584b51eF5236f7726Dea5A0FB6B3cA94AeC`, 0/5/9 → unset.
`OptimismPortal2.respectedGameType` → 8. `DisputeGameFactory.initBonds(8)` → 1 wei.

## Addresses

platforms-1 is not in the superchain-registry, so the task reads its addresses from
[addresses.json](./addresses.json) via `fallbackAddressesJsonPath`. Every address there was
taken from the chain's op-deployer state (`devnets-private@8810e39`
`stg/platforms-1/op-deployer/state.json` and `intent.toml`) and cross-checked on-chain against
`SystemConfig`, `OptimismPortal2`, `DisputeGameFactory` and `ProxyAdmin` getters.

## Absolute prestate

platforms-1 is not in any kona registry snapshot, so the standard
`kona-client/v1.7.0-rc.2` prestate does not contain it. `cannonKonaPrestate` is a **custom**
reproducible build at that same release with platforms-1's chain config baked in:

| Field | Value |
|---|---|
| Prestate | `0x030bec4509e7d0cf41cbd686cfeeca04f4cdb0c4048605a2f275e4f6edeaa73b` |
| Variant | `kona-client-int` (`prestate-artifacts-cannon-interop`, cannon64-kona-interop) |
| Source | `ethereum-optimism/optimism` tag `kona-client/v1.7.0-rc.2` = commit `64b043ea5bbca9bc6e57e0f1c8df0404b4cf5f68` |
| Build | `KONA_CUSTOM_CONFIGS_DIR=<configs> just reproducible-prestate` (repo root) |

The build embeds platforms-1's `chainList.json` + `configs.json` together with a single-chain
dependency set, mirroring what the superchain registry generates for a chain that has no
depset of its own. Both config files are committed at
`devnets-private@8810e39` `stg/platforms-1/platforms-1/`, and the resulting hash is recorded
in that devnet's `op-program/prestates.json`, so this prestate is reproducible from that
commit. Regenerate it with:

```bash
netchef fault-proofs generate-prestates \
  --devnet-dir <devnets-private>/stg/platforms-1 \
  --monorepo-dir <optimism> \
  --prestate-type konaInterop
```

which builds at the `kona-program` ref pinned in that devnet's `manifest.yaml`
(`kona-client/v1.7.0-rc.2`). Requires infrastructure-services#1430 for the hardfork encoding;
#1426 (merged) for the build path.

**The preimage must be uploaded to `gs://oplabs-network-data/proofs/kona/cannon/` before execution**, or
op-challenger and vm-runner cannot fetch it. `netchef fault-proofs generate-prestates` uploads
there itself unless `--skip-gcp-upload` is passed.

Also note platforms-1's op-challenger currently runs
`OP_CHALLENGER_TRACE_TYPE=cannon,cannon-kona`. netchef only selects
`super-cannon-kona` for chains with the interop fault-proof feature
(`pkg/generators/k8s/service/challenger.go:183-187`), which platforms-1 does not have, so after
this upgrade the respected game type would be one the deployed challenger does not play. That
is a devnet deployment change rather than part of this task's calldata, but it needs to land
alongside it.

## Anchor state

The starting anchor is a single-chain super root at finalized L2 block 6738774
(timestamp 1789068486), read from platforms-1's op-supernode `superroot_atTimestamp` on
2026-09-10. It is part of the signed calldata and is fixed once published — regenerate it and
the VALIDATION.md hashes if this task is re-dated.

## Simulation

```
cd src
just simulate-stack sep 108-U20-platforms-1

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 108-U20-platforms-1
```
