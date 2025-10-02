# 029-swell-main-u13-to-u16a

Status: [READY TO SIGN]()

## Objective

This task upgrades Swell Mainnet to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/029-swell-main-u13-to-u16a
SIMULATE_WITHOUT_WALLET=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/029-swell-main-u13-to-u16a
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
