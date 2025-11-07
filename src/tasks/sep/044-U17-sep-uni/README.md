# 041-U17-sep-uni

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task upgrades Unichain Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/041-U17-sep-uni
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/041-U17-sep-uni
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
