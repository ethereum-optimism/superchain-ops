# 053-U18-op-betanets-v3

Status: [READY TO SIGN]

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