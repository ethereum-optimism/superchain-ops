# 060-U18-rev-share-betanet

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xbbe711085bd8a3b44935cd763335f5a68c5a3a1c1290af22b3b75fc560e95bb7)

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
