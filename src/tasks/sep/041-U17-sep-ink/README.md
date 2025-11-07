# 038-U17-sep-op-sony-ink

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task upgrades OP, Soneium Minato, Ink Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/038-U17-sep-op-sony-ink
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/038-U17-sep-op-sony-ink
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
