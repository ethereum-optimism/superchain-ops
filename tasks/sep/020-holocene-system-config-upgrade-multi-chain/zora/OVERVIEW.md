# Holocene Hardfork - SystemConfig Upgrade
Upgrades the `SystemConfig.sol` contract for Holocene.

The batch will be executed on chain ID `11155111`, and contains `1` transactions.

## Tx #1: Upgrade `SystemConfig` proxy
Upgrades the `SystemConfig` proxy to the new implementation, featuring configurable EIP-1559 parameters.

**Function Signature:** `upgrade(address,address)`

**To:** `0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec4000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb0800000000000000000000000029d06ed7105c7552efd9f29f3e0d250e5df412cd`

### Inputs
**_proxy:** `0xB54c7BFC223058773CF9b739cC5bd4095184Fb08`

**_implementation:** `0x29d06Ed7105c7552EFD9f29f3e0d250e5df412CD`

