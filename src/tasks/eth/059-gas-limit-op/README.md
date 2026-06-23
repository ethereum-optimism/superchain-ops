# 059-gas-limit-op

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **OP Mainnet** (chainId `10`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing `setGasLimit`
re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the on-chain
value.

This task re-affirms OP Mainnet's current on-chain gas limit:
- `gasLimit`: 40,000,000 (unchanged — re-set to trigger the ConfigUpdate)

OP Mainnet's SystemConfig is owned by the **Foundation Upgrade Safe**
(`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`), so this task is rooted there. It runs
**after Karst activates on Mainnet (July 8, 2026)**, i.e. after the U19 tasks 053/054 and
FUS rotation tasks 055/056.

> [!IMPORTANT]
> The FUS nonce override in `config.toml` is set to 61 (live 57 + four pending tasks:
> 053→57, 054→58, 055-fus-rotation-1→59, 056-fus-rotation-2→60). VERIFY the live nonce
> before signing:
> `cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" --rpc-url mainnet`

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 059-gas-limit-op

# Sign
USE_KEYSTORE=1 just sign-stack eth 059-gas-limit-op

# Execute
cd src/tasks/eth/059-gas-limit-op
SIGNATURES=0x just execute
```
