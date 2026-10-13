# 075-fos-rotation

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task removes a FoundationOperationsSafe owner and replaces it with a new one.

## Simulation

To simulate this task in the context of the full task stack:

```bash
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack eth 075-fos-rotation
```

## Signing

```bash
cd src
just sign-stack eth 075-fos-rotation
```
