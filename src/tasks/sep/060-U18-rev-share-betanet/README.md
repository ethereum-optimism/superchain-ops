# 060-U18-rev-share-betanet

Status: READY TO SIGN

## Objective

Updates RevShare Betanet (revshare-beta-0) to U18.

## Simulation & Signing

```bash
cd src/tasks/sep/060-U18-rev-share-betanet

# Testing
just simulate-stack sep 060-U18-rev-share-betanet

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 060-U18-rev-share-betanet
SIGNATURES=0x just execute
```
