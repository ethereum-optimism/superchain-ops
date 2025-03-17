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

The prestate hash used is: `0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01`.
Which was taken from [validation/standard/standard-prestates.toml](https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/validation/standard/standard-prestates.toml#L14).

The input can therefore be generated [from](https://github.com/ethereum-optimism/superchain-registry/blob/fb6f538e17ee296b19536b03b8c73adc6041c60d/superchain/configs/sepolia/op.toml#L58-L59):

```
cast calldata \
  "updatePrestate((address,address,bytes32)[])" \
  "[(0x034edD2A225f7f429A63E0f1D2084B9E0A93b538, 0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc, 0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01)]"
```

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/032-op-pectra-defence/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
