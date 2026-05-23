# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes):
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's _validate block includes assertions to confirm the task ran correctly. State Changes can also be manually reviewed in Tenderly, using the link shown in the terminal during simulation.

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### OPE Admin Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0x3da6b4be1d489ee07ba8f13a39867f50766e73c3f0edf2e5ccd90c6f06b1936c`

## Understanding Task Calldata

The task batches two calls on `SystemConfigProxy` (`0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`):

1. `setBatcherHash(bytes32(uint256(uint160(0xdead000000000000000000000000000000000001))))`
2. `setUnsafeBlockSigner(0xdead000000000000000000000000000000000002)`

Verify the inner calldata fingerprints:

```bash
cast calldata "setBatcherHash(bytes32)" 0x000000000000000000000000dead000000000000000000000000000000000001
cast calldata "setUnsafeBlockSigner(address)" 0xdead000000000000000000000000000000000002
```

### Task Calldata

```
<TBD_CALLDATA>
```

## Task State Changes

- `SystemConfigProxy.batcherHash()` updates to `0x000000000000000000000000dead000000000000000000000000000000000001`
- `SystemConfigProxy.unsafeBlockSigner()` updates to `0xdead000000000000000000000000000000000002`
- OPE Admin Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`) nonce increments by 1

## Post-execution verification

```bash
cast call 0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc "batcherHash()(bytes32)" --rpc-url <SEPOLIA_RPC>
# Expected: 0x000000000000000000000000dead000000000000000000000000000000000001

cast call 0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc "unsafeBlockSigner()(address)" --rpc-url <SEPOLIA_RPC>
# Expected: 0xdead000000000000000000000000000000000002
```
