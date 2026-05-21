# 077-migrations-sop-1-set-respected-game-type

Status: DRAFT — NOT READY TO SIGN

## Objective

Sets the respected dispute game type to game type 0 (Permissionless / FaultDisputeGame) on the OptimismPortal for `migrations-sop-1` (chainId 420120110) on Sepolia. This must run after [076-migrations-sop-1-add-game-type](../076-migrations-sop-1-add-game-type/) registers FDG with the DisputeGameFactory.

Executed by the L1 ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`), which is also the chain's Guardian (per the Chain Migration Log).

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/077-migrations-sop-1-set-respected-game-type
just simulate-stack sep 077-migrations-sop-1-set-respected-game-type
```

Signing commands:
```bash
cd src/tasks/sep/077-migrations-sop-1-set-respected-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
