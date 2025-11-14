# 040-U17-soneium

Status: [READY TO SIGN]

## Objective

This task upgrades Soneium Minato Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/040-U17-soneium
just simulate-stack sep 040-U17-soneium <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/040-U17-soneium
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
