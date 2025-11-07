# 042-U17-sep-arena-z

Status: [READY TO SIGN]

## Objective

This task upgrades Arena-Z Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/042-U17-sep-arena-z
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/042-U17-sep-arena-z
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
