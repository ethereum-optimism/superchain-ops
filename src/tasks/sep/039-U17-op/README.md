# 039-U17-op

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xfb6e8295b69caa19b285df3275e9bccd04296dbca0fa4214539e7eb2728b2224)

## Objective

This task upgrades OP Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/039-U17-op
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/039-U17-op
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
