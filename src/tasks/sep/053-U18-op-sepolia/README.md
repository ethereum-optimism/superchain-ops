# 052-U18-op-betanets

Status: [READY TO SIGN]

## Objective

Updates OP Labs Betanets (both Permissioned and Permissionless networks) to U18.

## Simulation & Signing

```bash
cd src/tasks/sep/053-U18-op-sepolia

# Testing
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 052-U18-op-betanets
SIGNATURES=0x just execute
```