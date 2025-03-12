# ProxyAdminOwner - Update Prestate Hash

Status: DRAFT, NOT READY TO SIGN

## Objective

This task deploys new dispute games with updated prestate hashes on OP Sepolia.

This updated prestate hash corresponds with the hardfork to support the L1 Pectra upgrade.

## Input data derivation:

The `OPPrestateUpdater` contract was deployed in advance to [0x6E34d06bA5FcA20269036E7c6F3Bf3f774a9A8a6](https://etherscan.io/address/0x6e34d06ba5fca20269036e7c6f3bf3f774a9a8a6).

The `StandardValidator180` contract was deployed in advance to [0xFDa93f2Db6676541dDE71165681d0f23B25163dC](https://etherscan.io/address/0xFDa93f2Db6676541dDE71165681d0f23B25163dC).


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

The input can therefore be generated [from](https://github.com/ethereum-optimism/superchain-registry/blob/fb6f538e17ee296b19536b03b8c73adc6041c60d/superchain/configs/mainnet/op.toml#L58-L59):

```
cast calldata \
  "updatePrestate((address,address,bytes32)[])" \
  "[(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290, 0x543bA4AADBAb8f9025686Bd03993043599c6fB04, 0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd)]"
```

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/031-op-mainnet-pectra-defence/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
