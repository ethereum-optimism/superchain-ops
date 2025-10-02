# 035-base-sep-fusaka-prestate

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task uses `op-contract/v4.1.0` OPContractsManager to update the prestate of Base Sepolia to the Fusaka compatible prestate.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/035-base-sep-fusaka-prestate
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <NestedSafe1|NestedSafe2>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/035-base-sep-fusaka-prestate
just --dotenv-path $(pwd)/.env sign <NestedSafe1|NestedSafe2>
```
