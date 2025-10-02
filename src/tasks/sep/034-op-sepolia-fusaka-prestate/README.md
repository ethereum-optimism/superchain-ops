# 034-op-sepolia-fusaka-prestate

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task uses `op-contract/v4.1.0` OPContractsManager to update the prestate of OP Sepolia to the Fusaka compatible prestate.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/034-op-sepolia-fusaka-prestate
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/034-op-sepolia-fusaka-prestate
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
