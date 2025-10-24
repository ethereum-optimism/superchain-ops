# 038-opcm-upgrade-superchainconfig-v500-bn-u17

Status: [DRAFT, NOT READY TO SIGN]

```bash
cd src/tasks/sep/038-opcm-upgrade-superchainconfig-v500-bn-u17
# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or just sign-stack sep 038-opcm-upgrade-superchainconfig-v500-bn-u17
SIGNATURES=0x just execute
```