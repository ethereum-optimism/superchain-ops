# 104-gas-params-soneium-minato

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **Soneium Testnet Minato** (chainId `1946`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing the SystemConfig gas
params re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the
on-chain value.

This task re-affirms Soneium Minato's current on-chain gas params:
- `gasLimit`: 40,000,000 (unchanged)
- `eip1559Denominator`: 250, `eip1559Elasticity`: 10 (current on-chain values, unchanged)

This is a **reference task**: the SystemConfig is owned by the chain operator's Safe
(`0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65`), not the Foundation Upgrade Safe, so the
task is rooted at that owner (`safeAddressString = "SystemConfigOwner"`) and executed by the
operator. It should be run **after Karst activates on Sepolia (June 17, 2026)**.

> [!IMPORTANT]
> Verify the SystemConfigOwner Safe nonce in `config.toml`'s `[stateOverrides]` against the
> live value before signing:
> `cast call 0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65 "nonce()(uint256)" --rpc-url sepolia`

## Simulation & Signing

```bash
# Simulate
just simulate-stack sep 104-gas-params-soneium-minato

# Sign
USE_KEYSTORE=1 just sign-stack sep 104-gas-params-soneium-minato

# Execute
cd src/tasks/sep/104-gas-params-soneium-minato
SIGNATURES=0x just execute
```
