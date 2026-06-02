# 053-gas-params-op: (Ethereum) Increase gas target : OP Mainnet

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Sets the following gas params in the SystemConfig contract for OP Mainnet:
* gasLimit: 80_000_000 (previously 40_000_000)
* eip1559_elasticity: 2 (unchanged)
* eip1559_denominator: 250 (unchanged)

This doubles the block gasLimit from 40M to 80M while keeping the EIP-1559 elasticity at 2, which has the effect of 2x'ing the gasTarget from 20Mgas/block to 40Mgas/block on op-mainnet:

```
gasTarget = (onchain gasLimit) / (eip1559_elasticity) = 80Mgas / 2 = 40Mgas/block
```

With 2s blocks this raises the target from 10Mgas/s to 20Mgas/s.

### Timing

Expected to be executed once pre-activation performance testing confirms op-mainnet can sustain 20Mgas/s.

## Simulation & Signing

### Safe: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (FoundationUpgradeSafe)
Simulation commands:
```bash
cd src/tasks/eth/053-gas-params-op
just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
```

Signing commands:
```bash
cd src/tasks/eth/053-gas-params-op
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```
