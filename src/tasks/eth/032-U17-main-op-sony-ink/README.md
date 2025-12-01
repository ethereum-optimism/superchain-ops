# 032-U17-main-op-sony-ink

Status: [EXECUTED](https://etherscan.io/tx/0xf556934cb4de1ab40a4cfba17856cd601cbc8b875b96a9ccd8ee32bcd363abf5)

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
