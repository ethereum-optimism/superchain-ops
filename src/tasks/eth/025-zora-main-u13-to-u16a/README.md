# 025-zora-main-u13-to-u16a

Status: [EXECUTED](https://etherscan.io/tx/0x3c9df2c9f2502ed27df838f21bf474be0544246f8c0c3513a698d81e0c2890ae)

## Objective

This task upgrades Zora Mainnet to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/025-zora-main-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/025-zora-main-u13-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
