# 080-migrations-sop-1-add-game-type

Status: CANCELLED

- Already executed at block 10937343 ([tx `0x6d72b29e…`](https://sepolia.etherscan.io/tx/0x6d72b29e51559778653d6581d63a921deac46eb52948b098cfc922776fb390ed)) by the netchef bring-up of the `migrated-sop-1` permissionless receiving infra. On-chain `gameArgs(0)` uses a different prestate (`0x038c5780…`) and a fresh DelayedWETH (`0x82f1d0b2…`) than this config — do not re-run.

## Objective

Adds the permissionless dispute game (game type 0, FaultDisputeGame) to the DisputeGameFactory for `migrations-sop-1` (chainId 420120110) on Sepolia. This is a pre-cutover prerequisite for the chain migration described in the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) — the chain is intended to be permissionless but does not yet have FDG registered.

The task is executed by the L1 ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`) via `OPCM.addGameType`.

## State Changes

Writes to `DisputeGameFactoryProxy` ([`0xD22e520F…23`](https://sepolia.etherscan.io/address/0xD22e520F9005402a80715A3C2A60a6271B823A23#readContract)) for chainId 420120110, game type 0 (CANNON / permissionless):

| Field | Current (on-chain) | New |
|-------|--------------------|-----|
| `gameImpls(0)` | `0x0000000000000000000000000000000000000000` | `0x6ddba09bc4ccb0d6ca9fc5350580f74165707499` |
| `gameArgs(0)` | `0x` (empty) | 124-byte blob: `prestate \| vm \| ASR \| weth \| chainId` |
| `initBonds(0)` | `0` | `80000000000000000` (0.08 ETH) |

- **Current values**: read on-chain on Sepolia at block 10900000 from the DGF (link above). Verified with `cast call 0xD22e520F… "gameImpls(uint32)(address)" 0`, etc.
- **New `gameImpls(0)`**: `faultDisputeGameV2Impl` field of the OPCM v6.0.0 implementations bundle, fetched at execution time from OPCM ([`0xf0a2e224…bd`](https://sepolia.etherscan.io/address/0xf0a2e224519e876979ea6b2cd15ef5cc3d6703bd)). OPCM version pinned in [superchain-registry standard-versions-sepolia.toml](https://github.com/ethereum-optimism/superchain-registry/blob/HEAD/validation/standard/standard-versions-sepolia.toml).
- **New `gameArgs(0)`**: constructed by OPCM. Prestate `0x0355d19a…6aed` is op-program v1.9.0-rc.1 Cannon64 (per the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e)); vm = `0x6463dee3…b908` (MIPS 1.9.0); ASR = `0x8Faf920f…1c5a` (from `SystemConfig.optimismPortal().anchorStateRegistry()`); weth = `0x4cA719DE…f169` (config); chainId = `420120110`.
- **New `initBonds(0)`**: 0.08 ETH — defined in [config.toml](./config.toml).

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/080-migrations-sop-1-add-game-type
just simulate-stack sep 080-migrations-sop-1-add-game-type
```

Signing commands:
```bash
cd src/tasks/sep/080-migrations-sop-1-add-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
