# 035-U17-main-unichain

Status: [READY TO SIGN]

## Objective

This task upgrades Unichain Mainnet to U17.

## Simulation & Signing

Simulation commands for each safe:

```bash
cd src/tasks/eth/035-U17-main-unichain

# Foundation - Simulate and Sign
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate foundation
just --dotenv-path $(pwd)/.env sign foundation

# Security Council - Simulate and Sign
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate council
just --dotenv-path $(pwd)/.env sign council

# Chain Governor - Simulate and Sign
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate chain-governor
just --dotenv-path $(pwd)/.env sign chain-governor
```