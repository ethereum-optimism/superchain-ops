# 051-op-betanet-set-respected-game-type

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x17db07eb40cd403162359e1575a773691553bfc8529f1bd773e3cfa56c04833e)

## Objective

This task sets the respected dispute game type to game type 0 (Permissionless) on OP Betanet for U18.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/051-op-betanet-set-respected-game-type
just simulate-stack sep 051-op-betanet-set-respected-game-type
```

Signing commands for each safe:
```bash
cd src/tasks/sep/051-op-betanet-set-respected-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```