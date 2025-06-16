# 014-worldchain-l1pao-transfers: Transfer L1 owners for Worldchain Mainnet (DisputeGameFactory, PermissionlessWETH, PermissionedWETH and L1PAO)

Status: [EXECUTED](https://etherscan.io/tx/0x9e26ec397a3467daef4ca9f79e2dda0b2d83c5adf764ebe93f4a3c746b266527)

## Objective

Transfer L1 owners for Worldchain Mainnet (DisputeGameFactory, PermissionlessWETH, PermissionedWETH and L1PAO)

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/eth/014-worldchain-l1pao-transfers
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/eth/014-worldchain-l1pao-transfers
just --dotenv-path $(pwd)/.env --justfile ../../../single.just sign
```
