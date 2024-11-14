# Holocene Hardfork - System Config Contract Upgrade
Upgrades the `SystemConfig.sol` contract for Holocene.

The batch will be executed on chain ID `11155111`, and contains `1` transactions.

## Tx #1: Upgrade `SystemConfig` proxy
Upgrades the `SystemConfig` proxy to the new implementation, featuring configurable EIP-1559 parameters.

**Function Signature:** `upgrade(address,address)`

**To:** `0x18d890A46A3556e7F36f28C79F6157BC7a59f867`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec4000000000000000000000000a6b72407e2dc9ebf84b839b69a24c88929cf20f700000000000000000000000029d06ed7105c7552efd9f29f3e0d250e5df412cd`

### Inputs
**_implementation:** `0x29d06Ed7105c7552EFD9f29f3e0d250e5df412CD`

**_proxy:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

