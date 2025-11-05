# 034-U17-main-arena-z-swell

Status: [READY TO SIGN]

## Objective

This task upgrades Arena-Z and Swell Mainnet to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/034-U17-main-arena-z-swell
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/034-U17-main-arena-z-swell
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
