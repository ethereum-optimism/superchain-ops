# 055-gas-params-op

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **OP Mainnet** (chainId `10`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing the SystemConfig gas
params re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the
on-chain value.

This task re-affirms OP Mainnet's current on-chain gas params:
- `gasLimit`: 40,000,000 (unchanged)
- `eip1559Denominator`: 250, `eip1559Elasticity`: 2 (current on-chain values, unchanged)

OP Mainnet's SystemConfig is owned by the **Foundation Upgrade Safe**
(`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`), so this task is rooted there. It runs
**after Karst activates on Mainnet (July 8, 2026)**, i.e. after the U19 tasks 053/054.

> [!IMPORTANT]
> The FUS nonce override in `config.toml` is set to 59 (live 57 + the two nonces consumed by
> U19 tasks 053 and 054). VERIFY the live nonce before signing:
> `cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" --rpc-url mainnet`

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 055-gas-params-op

# Sign
USE_KEYSTORE=1 just sign-stack eth 055-gas-params-op

# Execute
cd src/tasks/eth/055-gas-params-op
SIGNATURES=0x just execute
```
