# 013-gas-params-op: (Ethereum) Increase gas target : OP Mainnet

Status: [EXECUTED](https://etherscan.io/tx/0x942508d969539505689fb2c1d8feea9473d3fae2aa619d4a470097b7e5c4d105)

## Objective

Sets the following gas params in the SystemConfig contract for OP Mainnet:
* gasLimit: 40_000_000
* eip1559_elasticity: 2

This has the effect of setting the gasTarget to 20Mgas/block on op-mainnet

### Timing

Expected to be executed on May 22, 2025.

## Simulation & Signing

### Safe: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (FoundationUpgradeSafe)
Simulation commands:
```bash
cd src/improvements/tasks/eth/013-gas-params-op
just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```

Signing commands:
```bash
cd src/improvements/tasks/eth/013-gas-params-op
just --dotenv-path $(pwd)/.env --justfile ../../../single.just sign
```
