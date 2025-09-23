# 030-worldchain-l2pao-key-handback-over

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Transfer the L2 ProxyAdmin Owner for Worldchain Sepolia to Alchemy-controlled EOA.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/030-worldchain-l2pao-key-handback-over
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/030-worldchain-l2pao-key-handback-over
just --dotenv-path $(pwd)/.env sign
```
