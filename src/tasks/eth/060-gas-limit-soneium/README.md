# 060-gas-limit-soneium

Status: [READY TO SIGN]()

## Objective

Karst (U19) gas-limit reset for **Soneium** (chainId `1868`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing `setGasLimit`
re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the on-chain
value.

This task re-affirms Soneium's current on-chain gas limit:
- `gasLimit`: 40,000,000 (unchanged — re-set to trigger the ConfigUpdate)

Soneium's SystemConfig is owned by a **Soneium-operated 3-of-6 Safe**
(`0x509182eC226b3B71D36A3255A80EF0b1A9D43033`), so this task is rooted there and is signed
and executed by Soneium — **not** by any OP-controlled safe. It runs **after Karst activates
on Soneium** (`karst_time = 1783526401`, Wed 8 Jul 2026 16:00:01 UTC).

## Simulation & Signing

```bash
# Simulate
just simulate-stack eth 060-gas-limit-soneium

# Sign
just sign-stack eth 060-gas-limit-soneium

# Execute
cd src/tasks/eth/060-gas-limit-soneium
SIGNATURES=0x<concatenated-signatures> just execute
```
