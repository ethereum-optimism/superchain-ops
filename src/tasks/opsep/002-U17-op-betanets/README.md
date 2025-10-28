# 002-U17-op-betanets

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Updates OP Labs Betanets (both Permissioned and Permissionless networks) to U17.

## Simulation & Signing

```bash
cd src/tasks/opsep/002-U17-op-betanets

# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 002-U17-op-betanets
SIGNATURES=0x just execute
```
