# 051-op-betanet-set-respected-game-type

Status: [READY TO SIGN]

## Objective

This task sets the respected dispute game type to game type 0 (Permissionless) on OP Betanet for U18.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/051-op-betanet-set-respected-game-type
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env simulate
```

Signing commands for each safe:
```bash
cd src/tasks/sep/051-op-betanet-set-respected-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
