# 040-soneium-devnet-upgrade-v410

Status: [READY TO SIGN]

```bash
cd src/tasks/sep/040-soneium-devnet-upgrade-v410

# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign

SIGNATURES=0x just execute
```