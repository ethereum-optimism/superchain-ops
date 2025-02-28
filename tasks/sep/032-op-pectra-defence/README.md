# ProxyAdminOwner - Update Prestate Hash

Status: DRAFT, NOT READY TO SIGN

## Objective

This task deploys new dispute games with updated prestate hashes on OP Sepolia.

This updated prestate hash corresponds with the hardfork to support the L1 Pectra upgrade.

## Input data derivation:

The OPPrestateUpdater contract was deployed in advance to [0x8cB886373DC01CA0463E4d8DED639467Ff0989c2](https://sepolia.etherscan.io/address/0x8cB886373DC01CA0463E4d8DED639467Ff0989c2).

The input to the `updatePrestate()` function is an array of the following struct:

```solidity
  struct OpChainConfig {
      ISystemConfig systemConfigProxy;
      IProxyAdmin proxyAdmin;
      Claim absolutePrestate;
  }
```

The prestate hash used is: `0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd`.
Which was taken from [op-program/prestates/releases.json](https://github.com/ethereum-optimism/optimism/blob/8d0dd96e494b2ba154587877351e87788336a4ec/op-program/prestates/releases.json#L9).

The input can therefore be generated [from](https://github.com/ethereum-optimism/superchain-registry/blob/fb6f538e17ee296b19536b03b8c73adc6041c60d/superchain/configs/sepolia/op.toml#L58-L59):

```
cast calldata \
  "updatePrestate((address,address,bytes32)[])" \
  "[(0x034edD2A225f7f429A63E0f1D2084B9E0A93b538, 0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc, 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd)]"
```

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/holesky/001-pectra-defense/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
