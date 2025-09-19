# 033-arena-z-u15-to-u16a

Status: [READY TO SIGN]()

## Objective

This task upgrades Arena-Z Sepolia to U16a.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/033-arena-z-u15-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/033-arena-z-u15-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
