# ProxyAdminOwner - Set Dispute Game Implementation

Status: READY TO SIGN

## Objective

This task updates deploys new dispute games with upgrade prestate hashes on the [balrog devnet](https://github.com/ethereum-optimism/devnets/pull/34/files#diff-ffdd0d4ec399fb055a0a8d3eb731dcffcf272cec33691f93f1ba14dfe77931ed).

This updated prestate hash corresponds with the hardfork to support the L1 Pectra upgrade.

## Input data derivation:

The OPPrestateUpdater contract was deployed in advance to [0xcF818b7407755b2dA91B0bc9462303980C062BFC](https://holesky.etherscan.io/address/0xcF818b7407755b2dA91B0bc9462303980C062BFC).

The input to the `updatePrestate()` function is an array of the following struct:

```solidity
  struct OpChainConfig {
        ISystemConfig systemConfigProxy;
        IProxyAdmin proxyAdmin;
        Claim absolutePrestate;
    }
```

This task is updating [op](https://github.com/ethereum-optimism/superchain-registry/blob/fb6f538e17ee296b19536b03b8c73adc6041c60d/superchain/configs/sepolia/op.toml#L58-L59) and [soneium](https://github.com/ethereum-optimism/superchain-registry/blob/fb6f538e17ee296b19536b03b8c73adc6041c60d/superchain/configs/sepolia/soneium-minato.toml#L59-L60).

The prestate hash used for both chains is taken from [here](https://github.com/ethereum-optimism/optimism/blob/a0a2b36fb22d949cdfae241ff82c475d2d0cbae9/op-program/prestates/releases.json#L9).


The input can therefore be generated from:

```
cast calldata \
  "updatePrestate((address,address,bytes32)[])" \
  "[(0x4Ca9608Fef202216bc21D543798ec854539bAAd3, 0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0, 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd), (0x034edD2A225f7f429A63E0f1D2084B9E0A93b538, 0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc, 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd)]"
```

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/holesky/001-pectra-defense/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
