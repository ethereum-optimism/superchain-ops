# 026-mode-sep-u13-to-u16

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

This task upgrades Mode Sepolia to U16, executing U13, U14, U15 sequentially.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/026-mode-sep-u13-to-u16
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/justfile simulate council
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/026-mode-sep-u13-to-u16
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/justfile simulate foundation
```
