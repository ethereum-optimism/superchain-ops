# 030-fus-rotation

Status: [EXECUTED](https://etherscan.io/tx/0xc77e3390fe7e322fa64ecc707690d18202e24d1611b1c6a748182f991eb75ea1)

## Objective

This task removes a FoundationUpgradeSafe owner and replaces it with a new one.

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/eth/030-fus-rotation
SIMULATE_WITHOUT_LEDGER=1 just simulate
```

Signing commands:
```bash
cd src/tasks/eth/030-fus-rotation
just sign
```
