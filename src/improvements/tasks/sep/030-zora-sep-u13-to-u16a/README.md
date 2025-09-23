# 030-zora-sep-u13-to-u16a

Status: [READY TO SIGN]()

## Objective

This task upgrades Zora Sepolia to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/030-zora-sep-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/030-zora-sep-u13-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
