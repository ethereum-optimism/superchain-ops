# Validation

This document can be used to validate the inputs and result of the execution of the SystemConfig gas param transactions which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
```
------------------ Single Multisig EOA Data to Sign ------------------
  
Data to sign:
  vvvvvvvv
  0x1901a4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b73267260635470abc96835e98346a9345dea820004b4360eefad78fbfe5a627bb33c81
  ^^^^^^^^

  ---------- ATTENTION SIGNERS ----------
  Please verify that the 'Data to sign' displayed above matches:
  1. The data shown in the Tenderly simulation.
  2. The data shown on your hardware wallet.
  This is a critical step. Do not skip this verification.
  ---------------------------------------

------------------ Single Multisig EOA Hash to Approve ------------------
  0x743dd706945320e177596c79787ef320b3edea48de695c69b3d4bea2810521d7
  Domain Hash:     0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672
  Message Hash:    0x60635470abc96835e98346a9345dea820004b4360eefad78fbfe5a627bb33c81
```

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the gas params update for OP Mainnet.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `SystemConfig.setGasLimit(uint64 _gasLimit)`

This function is called with the following inputs:

- `_gasLimit`: 40_000_000

Command to encode:

```bash
cast calldata "setGasLimit(uint64)" 40000000
```

Resulting calldata:
```
0xb40a817c0000000000000000000000000000000000000000000000000000000002625a00
```


### Inputs to `SystemConfig.setEIP1559Params(uint32 _denominator, uint32 _elasticity)`

This function is called with the following inputs:

- `_denominator`: 250
- `_elasticity`: 2

Command to encode:

```bash
cast calldata “setEIP1559Params(uint32,uint32)” 250 2
```

Resulting calldata:
```
0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000002
```

# State Changes

## Single Safe State Overrides and Changes

This task is executed by the `FoundationUpgradesSafe`. Refer to the [generic single Safe execution validation document](../../../../../SINGLE-VALIDATION.md)
for the expected state overrides and changes.

Additionally, Safe-related nonces [will increment by one](../../../../../SINGLE-VALIDATION.md#nonce-increments).

## State Diffs

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

  ---

### `0x229047fed2591dbec1ef1118d64f7af3db9eb290`  ([SystemConfig](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L59)) - Chain ID: 10
  
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000068`
  - **Decoded Kind:** `uint64`
  - **Before:** `60000000`
  - **After:** `40000000`
  - **Summary:** gasLimit changes from 60M -> 40M
  - **Detail:** Sets the gas limit per op-mainnet block to 40M
  
- **Key:** `0x000000000000000000000000000000000000000000000000000000000000006a`
  - **Decoded Kind:** `uint32`
  - **Before:** `0`
  - **After:** `250`
  - **Summary:** eip1559Denominator changes from 0 (unset) to 250
  - **Detail:** Sets the eip1559Denominator to 250, which is no change from [the current default value used](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L27). We must set this value since we are also changing the eip1559Elasticity in the same tx.
  
- **Key:** `0x000000000000000000000000000000000000000000000000000000000000006a`
  - **Decoded Kind:** `uint32`
  - **Before:** `0`
  - **After:** `2`
  - **Summary:** eip1559Elasticity changes from 0 (unset) to 2
  - **Detail:** Sets the eip1559Denominator to 2. Its currently using [the default value of 6](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L25).
  
  ---
  
### `0x847b5c174615b1b7fdf770882256e2d3e95b9d92`  ([SystemConfigOwner](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L44) (GnosisSafe)) - Chain ID: 10
  
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `23`
  - **After:** `24`
  - **Summary:** nonce increments from 23 to 24
  - **Detail:** Increments the SystemConfigOwner (FoundationUpgradesSafe) nonce