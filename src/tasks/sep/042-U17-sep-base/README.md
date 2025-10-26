# 042-U17-sep-base

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task upgrades OP, Soneium Minato, Ink Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/042-U17-sep-base
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/042-U17-sep-base
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
