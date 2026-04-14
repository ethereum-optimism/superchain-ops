# 050-fus-rotation

Status: DRAFT

## Objective

This task removes a FoundationUpgradeSafe owner and replaces it with a new one.

## Simulation

To simulate this task in the context of the full task stack:

```bash
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack eth 050-fus-rotation
```

## Signing

```bash
cd src
just sign-stack eth 050-fus-rotation
```
