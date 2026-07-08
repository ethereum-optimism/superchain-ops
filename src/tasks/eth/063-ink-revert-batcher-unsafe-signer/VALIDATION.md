# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's `_validate` block asserts `SystemConfig.batcherHash()` and `SystemConfig.unsafeBlockSigner()` equal the configured (Gelato) values.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationOperationsSafe (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)
>
> - Domain Hash:  `TODO — regenerate with just simulate once the Gelato restore values and FOS nonce are pinned`
> - Message Hash: `TODO`
> - Safe Hash:    `TODO`

## Understanding Task Calldata

The task batches two `SystemConfig` setters through Multicall3, targeting the Ink mainnet `SystemConfigProxy` (`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`).

```bash
# setBatcherHash(bytes32) — Gelato batcher left-padded to 32 bytes
cast calldata "setBatcherHash(bytes32)" 0x000000000000000000000000<GELATO_BATCHER>
# selector: 0xc9b26f61

# setUnsafeBlockSigner(address) — Gelato unsafe block signer
cast calldata "setUnsafeBlockSigner(address)" <GELATO_UNSAFE_SIGNER>
# selector: 0x18d13918
```

## Task State Changes

### `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` (SystemConfigProxy) — Chain ID 57073

- `batcherHash()` reverts from the OPE batcher back to the pre-migration Gelato batcher.
- `unsafeBlockSigner()` reverts from the OPE sequencer back to the pre-migration Gelato unsafe block signer.

### FoundationOperationsSafe (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)

Nonce increments by 1.

> [!NOTE]
> The `SystemConfig.owner()` slot-`0x33` value is a simulation-only override modelling the post-migration state; it is not a state change produced by this task. Remove it once the forward migration has executed on-chain.

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "batcherHash()(bytes32)" --rpc-url mainnet
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "unsafeBlockSigner()(address)" --rpc-url mainnet
```
