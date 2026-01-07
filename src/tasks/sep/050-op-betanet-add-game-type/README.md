# 050-op-betanet-add-game-type

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xe9d6af9325d78cbb17e8cc6f054d66f38f26b09059b979dd076b97a87ec6dd52)

## Objective

This task adds the dispute game type 0 (Permissionless) to the Dispute Game Factory on OP Betanet for U18.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/050-op-betanet-add-game-type
just simulate-stack sep 050-op-betanet-add-game-type
```

Signing commands for each safe:
```bash
cd src/tasks/sep/050-op-betanet-add-game-type
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```