# 063-U18-rev-share-permissioned-betanet

Status: [READY TO SIGN]

## Objective

Updates RevShare Permissioned Betanet (revshare-beta-1) to U18.

## Simulation & Signing

```bash
cd src/tasks/sep/063-U18-rev-share-permissioned-betanet

# Testing
just simulate-stack sep 063-U18-rev-share-permissioned-betanet

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 063-U18-rev-share-permissioned-betanet
SIGNATURES=0x just execute
```
