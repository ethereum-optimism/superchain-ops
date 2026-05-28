# 084-migrations-sop-1-proposer-rotation

Status: DRAFT, NOT READY TO SIGN

## Objective

For the `migrations-sop-1` (chainId 420120110) DisputeGameFactory on Sepolia, this task does two things:

1. Rotate the **PermissionedDisputeGame** (PDG, game type 1) proposer and challenger to the `migrated-sop-1` receiving infrastructure.
2. Update the **absolute prestate** for BOTH the **FaultDisputeGame** (FDG, game type 0) and the **PermissionedDisputeGame** (PDG, game type 1) to the freshly-built `op-program/v1.9.0-rc.1` Cannon64 prestate `0x032ab5ac33a98dc99947c54eeb0bf84f22abe4be0b01537235218164492ecab9` covering migrations-sop-0 and migrations-sop-1 chain configs.

Neither implementation address changes (FDG impl stays `0x6ddba09b…`, PDG impl stays `0x58bf355C…`) — only the `gameArgs` blobs change for each game type, so the template emits one `setImplementation` call per game type.

This is Migration Log step **3a** (`DisputeGameFactory.setImplementation`).

- **DisputeGameFactoryProxy**: `0xD22e520F9005402a80715A3C2A60a6271B823A23`
- **Signer**: L1 ProxyAdminOwner Safe `0xe934Dc97E347C6aCef74364B50125bb8689c40ff`

## State Changes

Writes to `DisputeGameFactoryProxy` ([`0xD22e520F…23`](https://sepolia.etherscan.io/address/0xD22e520F9005402a80715A3C2A60a6271B823A23#readContract)) for chainId 420120110.

### Game type 0 (FDG — CANNON)

| `gameArgs(0)` field | Bytes | Current (on-chain) | New |
|---------------------|-------|--------------------|-----|
| prestate | 0–32 | `0x038c5780df7d899a222bcdd835efc7cbd05d7d19e09ba5d04f356bd040a4ec6c` | `0x032ab5ac33a98dc99947c54eeb0bf84f22abe4be0b01537235218164492ecab9` |
| vm | 32–52 | `0x6463dee3828677f6270d83d45408044fc5edb908` | `0x6463dee3828677f6270d83d45408044fc5edb908` (unchanged) |
| anchorStateRegistry | 52–72 | `0x8faf920fad8138debf666949b9e41ff71cce1c5a` | `0x8faf920fad8138debf666949b9e41ff71cce1c5a` (unchanged) |
| delayedWETH | 72–92 | `0x82f1d0b2d95a8660bee211be0dabd5177966e886` | `0x82f1d0b2d95a8660bee211be0dabd5177966e886` (unchanged) |
| l2ChainId | 92–124 | `420120110` | `420120110` (unchanged) |

`gameImpls(0)` is unchanged at `0x6ddba09bc4ccb0d6ca9fc5350580f74165707499`.

### Game type 1 (PDG — PERMISSIONED_CANNON)

| `gameArgs(1)` field | Bytes | Current (on-chain) | New |
|---------------------|-------|--------------------|-----|
| prestate | 0–32 | `0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c` | `0x032ab5ac33a98dc99947c54eeb0bf84f22abe4be0b01537235218164492ecab9` |
| vm | 32–52 | `0x6463dee3828677f6270d83d45408044fc5edb908` | `0x6463dee3828677f6270d83d45408044fc5edb908` (unchanged) |
| anchorStateRegistry | 52–72 | `0x8faf920fad8138debf666949b9e41ff71cce1c5a` | `0x8faf920fad8138debf666949b9e41ff71cce1c5a` (unchanged) |
| delayedWETH | 72–92 | `0x4ca719de2459ccf0a3194b2265f8870df7bcf169` | `0x4ca719de2459ccf0a3194b2265f8870df7bcf169` (unchanged) |
| l2ChainId | 92–124 | `420120110` | `420120110` (unchanged) |
| proposer | 124–144 | `0x31f018d02be7a6e89b8933bd28a05780a6ecf7c8` | `0x5e9eE0Aa455425AaD2B55742077F95113FbaeB71` |
| challenger | 144–164 | `0x55744b685bd143385d118fc1f413d2b93758602c` | `0x9805e7976880e6e48Ce765118846078B877d80D0` |

`gameImpls(1)` is unchanged at `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`.

- **Current values**: full gameArgs blobs read on-chain on Sepolia via `cast call 0xD22e520F… "gameArgs(uint32)(bytes)" {0,1}`. Decomposed per `LibGameArgs.encode` layout (permissionless = 124 bytes = prestate|vm|ASR|weth|chainId; permissioned = 164 bytes = prestate|vm|ASR|weth|chainId|proposer|challenger).
- **New prestate**: `0x032ab5ac33a98dc99947c54eeb0bf84f22abe4be0b01537235218164492ecab9` = `op-program/v1.9.0-rc.1` Cannon64, built locally from the migrations-sop chain configs (`<chain-id>-rollup.json` + `<chain-id>-genesis-l2.json` for both 420120109 and 420120110). Preimage uploaded to `gs://oplabs-network-data/proofs/op-program/cannon/`.
- **New proposer / challenger**: receiving infrastructure for the `migrated-sop-1` permissionless chain, per [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e).

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/084-migrations-sop-1-proposer-rotation
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
```

Signing commands:
```bash
cd src/tasks/sep/084-migrations-sop-1-proposer-rotation
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```
