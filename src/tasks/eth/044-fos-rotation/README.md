# 044-fos-rotation

Status: [EXECUTED](https://etherscan.io/tx/0xd9e4cc21adaf0bf19bdbf4abc65d02c740ac30f6548e2841208c43a08209b43f)

## Objective

This task removes 3 FoundationOperationsSafe owners and replaces them with new ones.

## Simulation

To simulate this task in the context of the full task stack:

```bash
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack eth 044-fos-rotation
```

## Signing

```bash
cd src
just sign-stack eth 044-fos-rotation
```
