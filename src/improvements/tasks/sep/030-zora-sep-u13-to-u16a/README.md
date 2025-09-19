# 030-zora-u13-to-u16a

Status: [READY TO SIGN]()

## Objective

This task upgrades Zora Sepolia to U16a, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/030-zora-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/justfile simulate council
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/030-zora-u13-to-u16a
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/justfile simulate foundation
```
