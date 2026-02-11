# 038-soneium-set-respected-game-type

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task sets the respected dispute game type to game type 0 (Permissionless) on Soneium Mainnet.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/038-soneium-set-respected-game-type
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env simulate council
```

Signing commands for each safe:
```bash
cd src/tasks/eth/038-soneium-set-respected-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign council
```
