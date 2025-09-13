# 024-mode-main-u13-to-u16/.env

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

This task upgrades Mode Mainnet to U16, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/eth/024-mode-main-u13-to-u16/.env
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/justfile simulate council
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/eth/024-mode-main-u13-to-u16/.env
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/justfile simulate foundation
```
