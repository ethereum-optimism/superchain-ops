# 034-op-ink-sep-fusaka-prestate

Status: [[EXECUTED](https://sepolia.etherscan.io/tx/0x02d13afd79fb045ab34a05e5f9bc7f23738afd739a042f97bc314ad9e90e282e)]

## Objective

This task uses `op-contract/v4.1.0` OPContractsManager to update the prestate of OP Sepolia and Ink Sepolia to the Fusaka compatible prestate.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/034-op-ink-sep-fusaka-prestate
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/034-op-ink-sep-fusaka-prestate
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign <council|foundation>
```
