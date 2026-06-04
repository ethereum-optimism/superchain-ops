# 054-gas-params-op-target: (Ethereum) Increase gas *target* (P0 contingency) : OP Mainnet

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Sets the following gas params in the SystemConfig contract for OP Mainnet:
* gasLimit: 80_000_000 (unchanged; set by `053-gas-params-op-p0`)
* eip1559_elasticity: 2 (previously 4)
* eip1559_denominator: 250 (unchanged)

This is the **P0 contingency** step. It is executed **only if** the gas target is reached
after `053-gas-params-op-p0` (which raised the gas limit to 40Mgas/s while holding the
target at 10Mgas/s). It lowers `eip1559_elasticity` back from 4 to 2, leaving the 80M
block gasLimit in place, which **doubles the gasTarget** while keeping the limit fixed:

```
gasTarget = (onchain gasLimit) / (eip1559_elasticity) = 80Mgas / 2 = 40Mgas/block  (2x)
gasLimit  = (onchain gasLimit)                        = 80Mgas         (unchanged)
```

With 2s blocks:
* gas **target**: 10Mgas/s → **20Mgas/s** (2x)
* gas **limit**: 40Mgas/s → **40Mgas/s** (unchanged)

> [!IMPORTANT]
> This task assumes `053-gas-params-op-p0` has already executed (gasLimit 80M,
> elasticity 4). The `config.toml` reproduces that post-053 state via `SystemConfig`
> storage overrides so the simulated diff shows the only real change (elasticity 4 → 2).
> If 053 has not executed, the on-chain pre-state differs and the hashes/diff below must
> be regenerated.

### P1 (future, not yet scaffolded)

The next planned step (P1) raises the gas **limit** an additional 2.5x, from 40Mgas/s to
**100Mgas/s** (block `gasLimit` 80M → 200M). The gas-target policy for P1 has not been
decided yet (e.g. hold target via elasticity, or let it scale), so P1 is intentionally
**not** scaffolded here. When it is, follow the same `SystemConfigGasParams` pattern as a
new task (`055-gas-params-op-...`), choosing `eip1559_elasticity` to match the desired
target:
* hold target at 20Mgas/s → `gasLimit = 200_000_000`, `eip1559_elasticity = 5`
* scale target to 50Mgas/s → `gasLimit = 200_000_000`, `eip1559_elasticity = 2`

### Timing

Executed only if monitoring after 053 shows the 10Mgas/s gas target is being reached and
the chain can sustain a 20Mgas/s target.

## Simulation & Signing

### Safe: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (FoundationUpgradeSafe)
Simulation commands:
```bash
cd src/tasks/eth/054-gas-params-op-target
just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
```

Signing commands:
```bash
cd src/tasks/eth/054-gas-params-op-target
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```
