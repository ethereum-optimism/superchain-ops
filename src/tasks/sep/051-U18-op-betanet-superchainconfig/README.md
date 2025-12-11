# 051-U18-op-betanet-superchainconfig

Status: [DRAFT]

```bash
cd src/tasks/sep/051-U18-op-betanet-superchainconfig
# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or just sign-stack sep 051-U18-op-betanet-superchainconfig
SIGNATURES=0x just execute
```