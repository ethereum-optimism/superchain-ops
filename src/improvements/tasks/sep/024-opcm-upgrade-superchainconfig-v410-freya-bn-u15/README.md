# 024-opcm-upgrade-superchainconfig-v410-freya-bn-u15

Status: [READY TO SIGN]()

```bash
cd src/improvements/tasks/sep/024-opcm-upgrade-superchainconfig-v410-freya-bn-u15
# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
just --dotenv-path $(pwd)/.env sign
# or just sign-stack sep 024-opcm-upgrade-superchainconfig-v410-freya-bn-u15
SIGNATURES=0x just execute
```