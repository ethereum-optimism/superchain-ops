# 060-gas-limit-unichain

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **Unichain** (chainId `130`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing `setGasLimit`
re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the on-chain
value.

This task re-affirms Unichain's current on-chain gas limit:
- `gasLimit`: 60,000,000 (unchanged — re-set to trigger the ConfigUpdate)

This is a **reference task**: the SystemConfig is owned by the chain operator's Safe
(`0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1`), not the Foundation Upgrade Safe, so the
task is rooted at that owner (`safeAddressString = "SystemConfigOwner"`) and executed by the
operator. It should be run **after Karst activates on Mainnet (July 8, 2026)**.

> [!IMPORTANT]
> Verify the SystemConfigOwner Safe nonce in `config.toml`'s `[stateOverrides]` against the
> live value before signing:
> `cast call 0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1 "nonce()(uint256)" --rpc-url mainnet`

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 060-gas-limit-unichain

# Sign
just sign-stack eth 060-gas-limit-unichain

# Execute
cd src/tasks/eth/060-gas-limit-unichain
SIGNATURES=0x just execute
```
