# 039-U17-sep-op

Status: [READY TO SIGN]

## Objective

This task upgrades OP Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/039-U17-sep-op
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/039-U17-sep-op
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
