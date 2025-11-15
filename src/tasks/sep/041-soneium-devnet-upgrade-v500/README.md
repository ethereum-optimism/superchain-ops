# 041-soneium-devnet-upgrade-v500

Status: [READY TO SIGN]

## Objective

Updates SONEIUM devnet to U17.

## Simulation & Signing

```bash
cd src/tasks/sep/041-soneium-devnet-upgrade-v500

# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign

SIGNATURES=0x just execute
```
