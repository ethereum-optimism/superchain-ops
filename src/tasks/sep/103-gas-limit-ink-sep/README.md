# 103-gas-limit-ink-sep

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xc95f8e7cfe6887bae6cb2011fedcc99faa86a483e8930c8038cdf00e02b6f872)

## Objective

Karst (U19) gas-limit reset for **Ink Sepolia Testnet** (chainId `763373`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing `setGasLimit`
re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the on-chain
value.

This task re-affirms Ink Sepolia's current on-chain gas limit:
- `gasLimit`: 30,000,000 (unchanged — re-set to trigger the ConfigUpdate)

This is a **reference task**: the SystemConfig is owned by the **OP Enterprise Safe**
(`0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`) — transferred from Gelato as part of the
101/102 migration tasks — not the Foundation Upgrade Safe, so the task is rooted at that
owner (`safeAddressString = "SystemConfigOwner"`) and executed by the operator. It should
be run **after Karst activates on Sepolia (June 17, 2026)**.

> [!IMPORTANT]
> Verify the SystemConfigOwner Safe nonce in `config.toml`'s `[stateOverrides]` against the
> live value before signing:
> `cast call 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E "nonce()(uint256)" --rpc-url sepolia`

## Simulation & Signing

```bash
# Simulate
just simulate-stack sep 103-gas-limit-ink-sep

# Sign
just sign-stack sep 103-gas-limit-ink-sep

# Execute
cd src/tasks/sep/103-gas-limit-ink-sep
SIGNATURES=0x just execute
```
