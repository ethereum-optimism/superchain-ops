# 059-gas-params-soneium

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **Soneium** (chainId `1868`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing the SystemConfig gas
params re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the
on-chain value.

This task re-affirms Soneium's current on-chain gas params:
- `gasLimit`: 40,000,000 (unchanged)
- `eip1559Denominator`: 250, `eip1559Elasticity`: 10 (current on-chain values, unchanged)

This is a **reference task**: the SystemConfig is owned by the chain operator's Safe
(`0x509182eC226b3B71D36A3255A80EF0b1A9D43033`), not the Foundation Upgrade Safe, so the
task is rooted at that owner (`safeAddressString = "SystemConfigOwner"`) and executed by the
operator. It should be run **after Karst activates on Mainnet (July 8, 2026)**.

> [!IMPORTANT]
> Verify the SystemConfigOwner Safe nonce in `config.toml`'s `[stateOverrides]` against the
> live value before signing:
> `cast call 0x509182eC226b3B71D36A3255A80EF0b1A9D43033 "nonce()(uint256)" --rpc-url mainnet`

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 059-gas-params-soneium

# Sign
USE_KEYSTORE=1 just sign-stack eth 059-gas-params-soneium

# Execute
cd src/tasks/eth/059-gas-params-soneium
SIGNATURES=0x just execute
```
