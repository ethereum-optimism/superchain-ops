# 041-U17-sep-mmz

Status: [READY TO SIGN]

## Objective

This task upgrades Metal, Mode and Zora Sepolia to U17.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/041-U17-sep-mmz
just simulate-stack sep 041-U17-sep-mmz <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/041-U17-sep-mmz

just --dotenv-path $(pwd)/.env sign <council|foundation>
```
