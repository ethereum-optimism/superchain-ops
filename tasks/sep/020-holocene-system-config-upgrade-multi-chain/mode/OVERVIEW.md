# Holocene Hardfork - SystemConfig Upgrade
Upgrades the `SystemConfig.sol` contract for Holocene.

The batch will be executed on chain ID `11155111`, and contains `1` transactions.

## Tx #1: Upgrade `SystemConfig` proxy
Upgrades the `SystemConfig` proxy to the new implementation, featuring configurable EIP-1559 parameters.

**Function Signature:** `upgrade(address,address)`

**To:** `0xE7413127F29E050Df65ac3FC9335F85bB10091AE`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec400000000000000000000000015cd4f6e0ce3b4832b33cb9c6f6fe6fc246754c200000000000000000000000029d06ed7105c7552efd9f29f3e0d250e5df412cd`

### Inputs
**_proxy:** `0x15cd4f6e0CE3B4832B33cB9c6f6Fe6fc246754c2`

**_implementation:** `0x29d06Ed7105c7552EFD9f29f3e0d250e5df412CD`

