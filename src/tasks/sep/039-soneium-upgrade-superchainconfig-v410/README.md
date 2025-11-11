# 039-soneium-upgrade-superchainconfig-v410

Status: [READY TO SIGN]()

```bash
cd src/tasks/sep/039-soneium-upgrade-superchainconfig-v410
# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or just sign-stack sep 039-soneium-upgrade-superchainconfig-v410
SIGNATURES=0x just execute
```