# 040-U17-sony

Status: [READY TO SIGN]

## Objective

This task upgrades Soneium Minato Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/040-U17-sony
just simulate-stack sep 040-U17-sony <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/040-U17-sony
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
