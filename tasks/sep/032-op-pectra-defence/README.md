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

The prestate hash used is: `0x03631bf3d25737500a4e483a8fd95656c68a68580d20ba1a5362cd6ba012a435`

The input can therefore be generated from:

```
cast calldata \
  "updatePrestate((address,address,bytes32)[])" \
  "[(0x9fb5e819fed7169a8ff03f7fa84ee29b876d61b4, 0xbd71120fc716a431aeab81078ce85ccc74496552, 0x03631bf3d25737500a4e483a8fd95656c68a68580d20ba1a5362cd6ba012a435)]"
```

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/holesky/001-pectra-defense/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
