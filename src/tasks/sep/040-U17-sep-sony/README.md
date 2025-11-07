# 039-U17-sep-sony

Status: [READY TO SIGN]

## Objective

This task upgrades Soneium Minato Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/040-U17-sep-sony
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/040-U17-sep-sony
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
