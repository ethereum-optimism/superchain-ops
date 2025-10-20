# 031-fos-rotation

Status: [EXECUTED](https://etherscan.io/tx/0xf77d17f21e1c3a3ace4b8c70e0185a041d287511d935d49cd18424c96e7689bb)

## Objective

This task removes a FoundationOperationsSafe owner and replaces it with a new one.

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/eth/031-fos-rotation
SIMULATE_WITHOUT_LEDGER=1 just simulate
```

Signing commands:
```bash
cd src/tasks/eth/031-fos-rotation
just sign
```
