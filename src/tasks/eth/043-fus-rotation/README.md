# 043-fus-rotation

Status: [EXECUTED](https://etherscan.io/tx/0x30ce04ba3d67b9f3a832df79c3a465a0876ccfe193ccf606cf00a4d8ae6d27a0)

## Objective

This task removes 3 FoundationUpgradeSafe owners and replaces them with new ones.

## Simulation

To simulate this task in the context of the full task stack:

```bash
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack eth 043-fus-rotation
```

## Signing

```bash
cd src
just sign-stack eth 043-fus-rotation
```
