# 057-gas-params-metal-mode

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **Metal L2** (chainId `1750`) and **Mode** (chainId `34443`)
on Mainnet, bundled into one task.

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing the SystemConfig gas
params re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the
on-chain value.

Metal and Mode share the same SystemConfig owner Safe (Conduit) and identical gas params,
so they are bundled into one task. This re-affirms each chain's current effective params:
- `gasLimit`: 30,000,000 (unchanged)
- `eip1559Denominator`: 250, `eip1559Elasticity`: 6 (these chains predate on-chain EIP-1559
  config; the values are their genesis/Canyon defaults from the superchain-registry,
  confirmed via the L2 block-header `extraData`. Writing them explicitly is a no-op.)

This is a **reference task**: the SystemConfig is owned by the chain operator's Safe
(`0x4a4962275DF8C60a80d3a25faEc5AA7De116A746`), not the Foundation Upgrade Safe, so the
task is rooted at that owner (`safeAddressString = "SystemConfigOwner"`) and executed by the
operator. It should be run **after Karst activates on Mainnet (July 8, 2026)**.

> [!IMPORTANT]
> Verify the SystemConfigOwner Safe nonce in `config.toml`'s `[stateOverrides]` against the
> live value before signing:
> `cast call 0x4a4962275DF8C60a80d3a25faEc5AA7De116A746 "nonce()(uint256)" --rpc-url mainnet`

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 057-gas-params-metal-mode

# Sign
USE_KEYSTORE=1 just sign-stack eth 057-gas-params-metal-mode

# Execute
cd src/tasks/eth/057-gas-params-metal-mode
SIGNATURES=0x just execute
```
