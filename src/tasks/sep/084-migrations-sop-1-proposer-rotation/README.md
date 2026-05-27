# 084-migrations-sop-1-proposer-rotation

Status: DRAFT, NOT READY TO SIGN

## Objective

Rotates the proposer for the `migrations-sop-1` (chainId 420120110) PermissionedDisputeGame (PDG, game type 1) on the Sepolia DisputeGameFactory. The PDG implementation contract is unchanged (`0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`); only the `gameArgs` are updated to embed the new OP proposer.

This is Migration Log step **3a** (`DisputeGameFactory.setImplementation`).

> **Note**: despite the task name "proposer-rotation", on-chain inspection shows the PDG proposer and challenger are **already** the OP-controlled addresses listed below. The only effective change in `gameArgs(1)` is the prestate — see the State Changes table.

- **DisputeGameFactoryProxy**: `0xD22e520F9005402a80715A3C2A60a6271B823A23`
- **Signer**: L1 ProxyAdminOwner Safe `0xe934Dc97E347C6aCef74364B50125bb8689c40ff`

The FDG slot (game type 0) is mirrored to its post-080 state in this config (impl `0x6ddba09b…`, 124-byte gameArgs) so the template's skip-if-unchanged guard fires and no FDG write is emitted. FDG was added in task 080 and is retained as the chain's primary permissionless dispute game.

## State Changes

Writes to `DisputeGameFactoryProxy` ([`0xD22e520F…23`](https://sepolia.etherscan.io/address/0xD22e520F9005402a80715A3C2A60a6271B823A23#readContract)) for chainId 420120110, game type 1 (PERMISSIONED_CANNON):

| `gameArgs(1)` field | Bytes | Current (on-chain) | New |
|---------------------|-------|--------------------|-----|
| prestate | 0–32 | `0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c` | `0x0355d19a9da58fccf469c60293543f95f520ef38c055a23502ee0bace5f06aed` |
| vm | 32–52 | `0x6463dee3828677f6270d83d45408044fc5edb908` | `0x6463dee3828677f6270d83d45408044fc5edb908` (unchanged) |
| anchorStateRegistry | 52–72 | `0x8faf920fad8138debf666949b9e41ff71cce1c5a` | `0x8faf920fad8138debf666949b9e41ff71cce1c5a` (unchanged) |
| delayedWETH | 72–92 | `0x4ca719de2459ccf0a3194b2265f8870df7bcf169` | `0x4ca719de2459ccf0a3194b2265f8870df7bcf169` (unchanged) |
| l2ChainId | 92–124 | `420120110` | `420120110` (unchanged) |
| proposer | 124–144 | `0x31f018d02be7a6e89b8933bd28a05780a6ecf7c8` | `0x31f018d02be7a6e89b8933bd28a05780a6ecf7c8` (unchanged) |
| challenger | 144–164 | `0x55744b685bd143385d118fc1f413d2b93758602c` | `0x55744b685bd143385d118fc1f413d2b93758602c` (unchanged) |

`gameImpls(1)` is unchanged at `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`.

- **Current values**: full 164-byte blob read on-chain on Sepolia at block 10900000 via `cast call 0xD22e520F… "gameArgs(uint32)(bytes)" 1`. Decomposed into fields per `LibGameArgs.encode` layout (permissioned: 164 bytes = prestate(32) | vm(20) | ASR(20) | weth(20) | chainId(32) | proposer(20) | challenger(20)).
- **New prestate**: `0x0355d19a…6aed` = op-program v1.9.0-rc.1 Cannon64, per [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e).

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
