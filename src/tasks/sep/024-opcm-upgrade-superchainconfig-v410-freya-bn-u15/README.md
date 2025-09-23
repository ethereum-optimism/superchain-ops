# 024-opcm-upgrade-superchainconfig-v410-freya-bn-u15

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x5a1d79494372decb0b00eee2adffbec3d3d4a38c7b5e183b59f46287021f8171)

```bash
cd src/improvements/tasks/sep/024-opcm-upgrade-superchainconfig-v410-freya-bn-u15
# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or just sign-stack sep 024-opcm-upgrade-superchainconfig-v410-freya-bn-u15
SIGNATURES=0x just execute
```