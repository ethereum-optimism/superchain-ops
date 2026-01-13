# 053-U18-op-betanets-v3

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xd48bb2c399bd31b1e0a2446963501a4beef08ab04be734b2ebf0736615eb2b11)

## Objective

Updates OP Labs Betanets (both Permissioned and Permissionless networks) to U18.

## Simulation & Signing

```bash
cd src/tasks/sep/053-U18-op-betanets-v3

# Testing
just simulate-stack sep 053-U18-op-betanets-v3

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 053-U18-op-betanets-v3
SIGNATURES=0x just execute
```