# 036-uni-sep-fusaka-prestate

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task uses `op-contract/v4.1.0` OPContractsManager to update the prestate of Unichain Sepolia to the Fusaka compatible prestate.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/036-uni-sep-fusaka-prestate
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env simulate
```

Signing commands for each safe:
```bash
cd src/tasks/sep/036-uni-sep-fusaka-prestate
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
