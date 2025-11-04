# 038-U17-op-betanets

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x4c9be011326c86d030e1d1973f06522fc447049e37a8febfe970c72dc2f3ae56)

## Objective

Updates OP Labs Betanets (both Permissioned and Permissionless networks) to U17.

## Simulation & Signing

```bash
cd src/tasks/sep/038-U17-op-betanets

# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 038-U17-op-betanets
SIGNATURES=0x just execute
```
