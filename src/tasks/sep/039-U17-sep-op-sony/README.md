# 039-U17-sep-op-sony

Status: [READY TO SIGN]

## Objective

This task upgrades OP and Soneium Minato Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/039-U17-sep-op-sony
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/039-U17-sep-op-sony
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
