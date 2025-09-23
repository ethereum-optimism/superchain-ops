# 026-opcm-upgrade-v410-freya-bn-u16

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xf282895ccc73c14161f347a4358fd68e11bd0e6091ee3c94adf277eb2cb8500d)

```bash
cd src/tasks/sep/026-opcm-upgrade-v410-freya-bn-u16

# Testing
SIMULATE_WITHOUT_WALLET=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
WALLET_TYPE=keystore just --dotenv-path $(pwd)/.env sign
# or WALLET_TYPE=keystore just sign-stack sep 026-opcm-upgrade-v410-freya-bn-u16
SIGNATURES=0x just execute
```