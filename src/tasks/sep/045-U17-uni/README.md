# 045-U17-uni

Status: [READY TO SIGN]

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
