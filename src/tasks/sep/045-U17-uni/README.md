# 041-U17-sep-uni

Status: [DRAFT, NOT READY TO SIGN]

## Objective

This task upgrades Unichain Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/041-U17-sep-uni
just simulate-stack eth 034-U17-main-arena-z-swell <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/041-U17-sep-uni
just --dotenv-path $(pwd)/.env sign <council|foundation>
```
