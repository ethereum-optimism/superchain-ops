# 076-migrations-sop-1-add-game-type

Status: DRAFT — NOT READY TO SIGN

## Objective

Adds the permissionless dispute game (game type 0, FaultDisputeGame) to the DisputeGameFactory for `migrations-sop-1` (chainId 420120110) on Sepolia. This is a pre-cutover prerequisite for the chain migration described in the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) — the chain is intended to be permissionless but does not yet have FDG registered.

The task is executed by the L1 ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`) via `OPCM.addGameType`.

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/076-migrations-sop-1-add-game-type
just simulate-stack sep 076-migrations-sop-1-add-game-type
```

Signing commands:
```bash
cd src/tasks/sep/076-migrations-sop-1-add-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
