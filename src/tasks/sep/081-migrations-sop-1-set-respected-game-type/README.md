# 081-migrations-sop-1-set-respected-game-type

Status: CANCELLED

- Already satisfied. `respectedGameType` has been `0` since chain bootstrap at block 10887907 ([tx `0x02db7429…`](https://sepolia.etherscan.io/tx/0x02db7429949a4b8da12426d51192c69674c575c35721b2d6bb45c2eb7a35b357)); `respectedGameTypeUpdatedAt` confirms it has never been any other value. The template would revert with `"Game type already set to target value"`.

## Objective

Sets the respected dispute game type to game type 0 (Permissionless / FaultDisputeGame) on the OptimismPortal for `migrations-sop-1` (chainId 420120110) on Sepolia. This must run after [080-migrations-sop-1-add-game-type](../080-migrations-sop-1-add-game-type/) registers FDG with the DisputeGameFactory.

Executed by the L1 ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`), which is also the chain's Guardian (per the Chain Migration Log).

## State Changes

| Target | Field | Current (on-chain) | New |
|--------|-------|--------------------|-----|
| AnchorStateRegistry ([`0x8Faf920f…1c5a`](https://sepolia.etherscan.io/address/0x8Faf920fAd8138DeBF666949b9e41ff71Cce1C5a#readContract)) | `respectedGameType()` | `1` (PERMISSIONED_CANNON) | `0` (CANNON / permissionless) |

- **Current value**: `1`, read on-chain on Sepolia at block 10900000 via `cast call 0x8Faf920f… "respectedGameType()(uint32)"`.
- **New value**: `0` — Migration Log cutover step to switch the chain's primary dispute game to the permissionless FDG added in 080. Source: [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e).

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/081-migrations-sop-1-set-respected-game-type
just simulate-stack sep 081-migrations-sop-1-set-respected-game-type
```

Signing commands:
```bash
cd src/tasks/sep/081-migrations-sop-1-set-respected-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
