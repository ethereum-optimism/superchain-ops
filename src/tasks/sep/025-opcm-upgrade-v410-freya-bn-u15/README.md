# 025-opcm-upgrade-v410-freya-bn-u15

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x96818c873717c91bad8cabb658050a639d02dd4c22e46365b98b105e448587e4)

```bash
cd src/tasks/sep/025-opcm-upgrade-v410-freya-bn-u15

# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 025-opcm-upgrade-v410-freya-bn-u15
SIGNATURES=0x just execute
```