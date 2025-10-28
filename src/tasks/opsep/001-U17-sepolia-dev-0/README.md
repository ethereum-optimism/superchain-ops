# 001-U17-sepolia-dev-0

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Updates OP Labs sepolia-dev-0 network to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/opsep/001-U17-sepolia-dev-0
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate
```

Signing commands for each safe:
```bash
cd src/tasks/opsep/001-U17-sepolia-dev-0
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
```
