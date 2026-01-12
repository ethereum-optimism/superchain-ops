# 053-U18-betanets-prestate-update

Status: [DRAFT]

## Objective

Updates OP Labs Betanets (both Permissioned and Permissionless networks) to U18.

## Simulation & Signing

```bash
cd src/tasks/sep/053-U18-betanets-prestate-update

# Testing
just simulate-stack sep 053-U18-betanets-prestate-update

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 053-U18-betanets-prestate-update
SIGNATURES=0x just execute
```