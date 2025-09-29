# 014-worldchain-l1pao-transfers: Transfer L1 owners for Worldchain Mainnet (DisputeGameFactory, PermissionlessWETH, PermissionedWETH and L1PAO)

Status: [CANCELLED]()

## Objective

Transfer L1 owners for Worldchain Mainnet (DisputeGameFactory, PermissionlessWETH, PermissionedWETH and L1PAO)

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/014-worldchain-l1pao-transfers
SIMULATE_WITHOUT_WALLET=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```

Signing commands for each safe:
```bash
cd src/tasks/eth/014-worldchain-l1pao-transfers
just --dotenv-path $(pwd)/.env --justfile ../../../single.just sign
```
