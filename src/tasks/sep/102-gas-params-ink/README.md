# 102-gas-params-ink

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **Ink Sepolia Testnet** (chainId `763373`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing the SystemConfig gas
params re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the
on-chain value.

This task re-affirms Ink Sepolia's current effective gas params:
- `gasLimit`: 30,000,000 (unchanged)
- `eip1559Denominator`: 250, `eip1559Elasticity`: 6 (Ink predates on-chain EIP-1559 config;
  these are its genesis/Canyon defaults from the superchain-registry. Writing them
  explicitly is a no-op.)

This is a **reference task**: the SystemConfig is owned by the chain operator's Safe
(`0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`), not the Foundation Upgrade Safe, so the
task is rooted at that owner (`safeAddressString = "SystemConfigOwner"`) and executed by the
operator. It should be run **after Karst activates on Sepolia (June 17, 2026)**.

> [!IMPORTANT]
> Verify the SystemConfigOwner Safe nonce in `config.toml`'s `[stateOverrides]` against the
> live value before signing:
> `cast call 0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb "nonce()(uint256)" --rpc-url sepolia`

## Simulation & Signing

```bash
# Simulate
just simulate-stack sep 102-gas-params-ink

# Sign
USE_KEYSTORE=1 just sign-stack sep 102-gas-params-ink

# Execute
cd src/tasks/sep/102-gas-params-ink
SIGNATURES=0x just execute
```
