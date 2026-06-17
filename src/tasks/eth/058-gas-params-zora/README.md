# 058-gas-params-zora

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **Zora** (chainId `7777777`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing the SystemConfig gas
params re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the
on-chain value.

This task re-affirms Zora's current effective gas params:
- `gasLimit`: 30,000,000 (unchanged)
- `eip1559Denominator`: 250, `eip1559Elasticity`: 6 (Zora predates on-chain EIP-1559 config;
  these are its genesis/Canyon defaults from the superchain-registry, confirmed via the L2
  block-header `extraData`. Writing them explicitly is a no-op.)

This is a **reference task**: the SystemConfig is owned by the chain operator's Safe
(`0xC72aE5c7cc9a332699305E29F68Be66c73b60542`), not the Foundation Upgrade Safe, so the
task is rooted at that owner (`safeAddressString = "SystemConfigOwner"`) and executed by the
operator. It should be run **after Karst activates on Mainnet (July 8, 2026)**.

> [!IMPORTANT]
> Verify the SystemConfigOwner Safe nonce in `config.toml`'s `[stateOverrides]` against the
> live value before signing:
> `cast call 0xC72aE5c7cc9a332699305E29F68Be66c73b60542 "nonce()(uint256)" --rpc-url mainnet`

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 058-gas-params-zora

# Sign
USE_KEYSTORE=1 just sign-stack eth 058-gas-params-zora

# Execute
cd src/tasks/eth/058-gas-params-zora
SIGNATURES=0x just execute
```
