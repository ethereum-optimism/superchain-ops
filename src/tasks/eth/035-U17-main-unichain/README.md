# 035-U17-main-unichain

Status: [READY TO SIGN]

## Objective

This task upgrades Unichain Mainnet to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/035-U17-main-unichain
just simulate-stack eth 035-U17-main-unichain <foundation|council|chain-governor>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/035-U17-main-unichain
just sign-stack eth 035-U17-main-unichain <foundation|council|chain-governor>
```