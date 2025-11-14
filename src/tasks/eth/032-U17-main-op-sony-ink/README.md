# 032-U17-main-op-sony-ink

Status: [READY TO SIGN]

## Objective

This task upgrades OP, Soneium, Ink Mainnet to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/032-U17-main-op-sony-ink
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/032-U17-main-op-sony-ink
just sign <council|foundation>
```
