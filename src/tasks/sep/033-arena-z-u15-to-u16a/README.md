# 033-arena-z-u15-to-u16a

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xe0452a3e93c55023b9be3b45e554546201960643eee4d5b44abea07ee53f901c)

## Objective

This task upgrades Arena-Z Sepolia to U16a.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/033-arena-z-u15-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/033-arena-z-u15-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
