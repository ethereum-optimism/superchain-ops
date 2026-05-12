# 050-fus-rotation

Status: [EXECUTED](https://etherscan.io/tx/0x9592d29403a878a9ad6041a8cac8f0789a160fe4ea7b5cf364aff4a08b5656ee)

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
