# 015-l1-ownership-transfers-uni: Transfer L1 owners for Unichain Sepolia (DGF, PermissionlessWETH, PermissionedWETH and L1PAO)

Status: [DRAFT]()

## Objective

Transfer the L1 owners for the Unichain Sepolia (DGF, PermissionlessWETH, PermissionedWETH and L1PAO).

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/sep/015-l1-ownership-transfers-uni
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/single.just simulate
```

Signing commands for each safe:
```bash
cd src/improvements/tasks/sep/015-l1-ownership-transfers-uni
just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/single.just sign
```
