# 048-soneium-set-respected-game-type

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x9a84f81eb22d116eab397dbd5d8f8b42de6dfd7e3f54ef430ea925885c3c5e53)

## Objective

This task sets the respected dispute game type to game type 0 (Permissionless) on Soneium Minato Testnet.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/048-soneium-set-respected-game-type
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env simulate council
```

Signing commands for each safe:
```bash
cd src/tasks/sep/048-soneium-set-respected-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign council
```
