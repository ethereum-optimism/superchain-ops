# 045-U17-uni

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xb438e78730e07f12bebaa3678e2cfae57f24fd6f45391e18c9136651b3605f75)

## Objective

This task upgrades Unichain Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/045-U17-uni
just simulate-stack sep 045-U17-uni
```

Signing commands for each safe:
```bash
cd src/tasks/sep/045-U17-uni
just --dotenv-path $(pwd)/.env sign
```
