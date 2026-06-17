# 105-gas-params-unichain

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **Unichain Sepolia Testnet** (chainId `1301`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing the SystemConfig gas
params re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the
on-chain value.

This task re-affirms Unichain Sepolia's current on-chain gas params:
- `gasLimit`: 60,000,000 (unchanged)
- `eip1559Denominator`: 50, `eip1559Elasticity`: 12 (current on-chain values, unchanged —
  note Unichain Sepolia uses denominator 50, not 250)

This is a **reference task**: the SystemConfig is owned by the chain operator's Safe
(`0x325B777f8F0bC71fb6b617Bc41A8703CA7077891`), not the Foundation Upgrade Safe, so the
task is rooted at that owner (`safeAddressString = "SystemConfigOwner"`) and executed by the
operator. It should be run **after Karst activates on Sepolia (June 17, 2026)**.

> [!IMPORTANT]
> Verify the SystemConfigOwner Safe nonce in `config.toml`'s `[stateOverrides]` against the
> live value before signing:
> `cast call 0x325B777f8F0bC71fb6b617Bc41A8703CA7077891 "nonce()(uint256)" --rpc-url sepolia`

## Simulation & Signing

```bash
# Simulate
just simulate-stack sep 105-gas-params-unichain

# Sign
USE_KEYSTORE=1 just sign-stack sep 105-gas-params-unichain

# Execute
cd src/tasks/sep/105-gas-params-unichain
SIGNATURES=0x just execute
```
