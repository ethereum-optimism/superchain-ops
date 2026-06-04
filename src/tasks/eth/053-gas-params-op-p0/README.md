# 053-gas-params-op-p0: (Ethereum) Increase gas *limit* (P0) : OP Mainnet

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Sets the following gas params in the SystemConfig contract for OP Mainnet:
* gasLimit: 80_000_000 (previously 40_000_000)
* eip1559_elasticity: 4 (previously 2)
* eip1559_denominator: 250 (unchanged)

This is the **P0** step of an incremental gas roll-out. It doubles the block `gasLimit`
from 40M to 80M while simultaneously doubling `eip1559_elasticity` from 2 to 4, so that
the **gasTarget is unchanged** and only the **gasLimit** doubles:

```
gasTarget = (onchain gasLimit) / (eip1559_elasticity) = 80Mgas / 4 = 20Mgas/block  (unchanged)
gasLimit  = (onchain gasLimit)                        = 80Mgas        (2x)
```

With 2s blocks:
* gas **limit**: 20Mgas/s → **40Mgas/s** (2x)
* gas **target**: 10Mgas/s → **10Mgas/s** (unchanged)

Raising elasticity rather than only the limit lets blocks absorb 2x the burst capacity
without raising the steady-state target, which can stay at 10Mgas/s given the current
lack of congestion.

> [!NOTE]
> If the target is subsequently reached, the gas target is doubled to 20Mgas/s by the
> follow-up contingency task `054-gas-params-op-target` (which lowers elasticity back to
> 2, keeping the 80M limit). The further P1 step (limit 2.5x → 100Mgas/s) is documented
> in `054-gas-params-op-target/README.md` and is not yet scaffolded.

### Timing

Expected to be executed once pre-activation performance testing confirms op-mainnet can
sustain a 40Mgas/s gas limit.

## Simulation & Signing

### Safe: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (FoundationUpgradeSafe)
Simulation commands:
```bash
cd src/tasks/eth/053-gas-params-op-p0
just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
```

Signing commands:
```bash
cd src/tasks/eth/053-gas-params-op-p0
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```
