# 026-opcm-upgrade-v410-freya-bn-u16

Status: [READY TO SIGN]()

```bash
cd src/improvements/tasks/sep/026-opcm-upgrade-v410-freya-bn-u16

# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 026-opcm-upgrade-v410-freya-bn-u16
SIGNATURES=0x just execute
```