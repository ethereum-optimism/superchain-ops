# 020-worldchain-l1-ownership-transfers: Transfer L1 owners for Worldchain Sepolia (DGF, PermissionlessWETH, PermissionedWETH and L1PAO)

Status: [READY TO SIGN]()

## Objective

Transfer the L1 owners for the Worldchain Sepolia (DisputeGameFactory, PermissionlessWETH, PermissionedWETH and L1PAO).

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/020-worldchain-l1-ownership-transfers
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/single.just simulate
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/020-worldchain-l1-ownership-transfers
just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/single.just sign
```
