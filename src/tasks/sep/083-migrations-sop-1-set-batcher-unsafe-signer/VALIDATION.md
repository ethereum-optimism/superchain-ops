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
> ### OPE Receiving Safe (Safe B) (`0xb3228B623da92283280C87aB8019A405967A2B8f`)
>
> - Domain Hash:  `0x3e8aab7bcaa16ba1ae02e15a7c0fcc9d46b96cb5afed054d4e620ccfc5f62f35`
> - Message Hash: `0x07536eacf65b13b285c67a2d9e7d1648f06ea7436c7b057c8754ba6cc70f1b1d`
> - Safe Hash:    `0x0abaf4fe85ada478fe15ac712f64eed4c9de9d192e0452ebb7b7e201ebc96505`

## Understanding Task Calldata

The task batches two calls on `SystemConfigProxy` (`0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`):

1. `setBatcherHash(bytes32(uint256(uint160(0x9bEE5085CB02BFb26E5838b88F2d3827401865Ce))))`
2. `setUnsafeBlockSigner(0x224C4E0a1d99CE75671C2C3f2a54ab775b999f90)`

Verify the inner calldata fingerprints:

```bash
cast calldata "setBatcherHash(bytes32)" 0x0000000000000000000000009bee5085cb02bfb26e5838b88f2d3827401865ce
cast calldata "setUnsafeBlockSigner(address)" 0x224C4E0a1d99CE75671C2C3f2a54ab775b999f90
```

### Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000120000000000000000000000000c771958af69d4fa44dec2555c41c48800ca1f9fc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024c9b26f610000000000000000000000009bee5085cb02bfb26e5838b88f2d3827401865ce00000000000000000000000000000000000000000000000000000000000000000000000000000000c771958af69d4fa44dec2555c41c48800ca1f9fc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002418d13918000000000000000000000000224c4e0a1d99ce75671c2c3f2a54ab775b999f9000000000000000000000000000000000000000000000000000000000
```

## Task State Changes

- `SystemConfigProxy.batcherHash()` updates to `0x0000000000000000000000009bee5085cb02bfb26e5838b88f2d3827401865ce`
- `SystemConfigProxy.unsafeBlockSigner()` updates to `0x224C4E0a1d99CE75671C2C3f2a54ab775b999f90`
- OPE Receiving Safe (Safe B) (`0xb3228B623da92283280C87aB8019A405967A2B8f`) nonce increments by 1

## Post-execution verification

```bash
cast call 0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc "batcherHash()(bytes32)" --rpc-url <SEPOLIA_RPC>
# Expected: 0x0000000000000000000000009bee5085cb02bfb26e5838b88f2d3827401865ce

cast call 0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc "unsafeBlockSigner()(address)" --rpc-url <SEPOLIA_RPC>
# Expected: 0x224C4E0a1d99CE75671C2C3f2a54ab775b999f90
```
