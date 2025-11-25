# 035-U17-main-unichain

Status: [EXECUTED](https://etherscan.io/tx/0x7c9e6b65258838fb38bc0bf584cb0c0802bc0dfbbe877a8639880e2ed88b3aa6)

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