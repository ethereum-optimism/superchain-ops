# 039-soneium-upgrade-superchainconfig-v410

Status: [READY TO SIGN]()

```bash
cd src/tasks/sep/039-soneium-upgrade-superchainconfig-v410
# Testing
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate

# Commands to execute via keystore (if not imported, use "cast wallet import" to add the signer's address)
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign

SIGNATURES=0x just execute
```