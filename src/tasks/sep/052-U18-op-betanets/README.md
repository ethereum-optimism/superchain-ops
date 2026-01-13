# 052-U18-op-betanets

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x53e6a4664fc3f33ddfa4fc1fee610ba86d8eb55198701371796d420f66b1ce50)

## Objective

Updates OP Labs Betanets (both Permissioned and Permissionless networks) to U18.

## Simulation & Signing

```bash
cd src/tasks/sep/052-U18-op-betanets

# Testing
just simulate-stack sep 052-U18-op-betanets

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 052-U18-op-betanets
SIGNATURES=0x just execute
```