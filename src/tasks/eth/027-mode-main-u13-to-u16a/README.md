# 027-mode-main-u13-to-u16a

Status: [EXECUTED](https://etherscan.io/tx/0x3ac45d51da454abfba887b5ab1dae831a78e068615893fb62d8034437bb17063)

## Objective

This task upgrades Mode Mainnet to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/027-mode-main-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/027-mode-main-u13-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
