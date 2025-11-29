# 038-world-sep-u13-to-u16a

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task upgrades Worldchain Sepolia to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/038-world-sep-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate
```

Signing commands for each safe:
```bash
cd src/tasks/sep/038-world-sep-u13-to-u16a
just --dotenv-path $(pwd)/.env sign
```
