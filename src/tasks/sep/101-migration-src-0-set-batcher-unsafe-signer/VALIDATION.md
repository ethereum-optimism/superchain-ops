# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's `_validate` block asserts `SystemConfig.batcherHash()` and `SystemConfig.unsafeBlockSigner()` equal the configured values. State changes can also be reviewed in Tenderly via the link printed during simulation.

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### OPE Receiving Safe / Safe B (`0xb3228B623da92283280C87aB8019A405967A2B8f`)
>
> - Domain Hash:  `0x3e8aab7bcaa16ba1ae02e15a7c0fcc9d46b96cb5afed054d4e620ccfc5f62f35`
> - Message Hash: `0xfbbcfe3ee83f92e962fef55be6e4f34a11f6a0393f65e20215f278ea35174811`
> - Safe Hash:    `0xfd32e22eae1927d52e161484f4798446fd5e606456247a17136e5105e0dda871`
>
> _Hashes generated via `just simulate` at the latest block with the state overrides in [config.toml](./config.toml) (Safe B nonce = 1; SystemConfig.owner → Safe B). The Domain Hash was also computed independently (`keccak256(abi.encode(0x47e7…9218, 11155111, 0xb3228B…)))`). If those overrides change (e.g. Safe B transacts before this task, or the on-chain owner transfer is already executed), re-run `just simulate` and replace the Message/Safe hashes before signing._

## Understanding Task Calldata

The task batches two `SystemConfig` setters through Multicall3, targeting the `migration-src-0` `SystemConfigProxy` (`0xeb776E1d4cda95D4155e73c5ceE34b9f7C2EE818`).

Verify the two inner calldata fingerprints:

```bash
# setBatcherHash(bytes32) — batcher address left-padded to 32 bytes
cast calldata "setBatcherHash(bytes32)" 0x00000000000000000000000004bf2305dc047e9a00ad71c08c9e8dec502091a2
# Expected: 0xc9b26f6100000000000000000000000004bf2305dc047e9a00ad71c08c9e8dec502091a2

# setUnsafeBlockSigner(address)
cast calldata "setUnsafeBlockSigner(address)" 0x5D2680A041a63376071512eBF6f7fB3380Edad02
# Expected: 0x18d139180000000000000000000000005d2680a041a63376071512ebf6f7fb3380edad02
```

The outer Multicall3 `aggregate3` blob is assembled by the framework and printed during simulation; confirm it contains both inner calls above and no others.

## Task State Changes

### `0xeb776E1d4cda95D4155e73c5ceE34b9f7C2EE818` (SystemConfigProxy) — Chain ID 420120140

- `batcherHash()` updates from `0x000…9829eb0da5d44de187ddbd8cd6daeb6fc9495931` to `0x000…04bf2305dc047e9a00ad71c08c9e8dec502091a2` (migration-dest-0 batcher).
- `unsafeBlockSigner()` updates from `0x5887E87eE14012453e5a3C101d8A7f42E0E99853` to `0x5D2680A041a63376071512eBF6f7fB3380Edad02` (migration-dest-0 sequencer).

### `0xb3228B623da92283280C87aB8019A405967A2B8f` (OPE Receiving Safe / Safe B)

Nonce increments by 1.

> [!NOTE]
> The `SystemConfig.owner()` change from EOA → Safe B is **not** part of this task; it is performed outside the ops repo. The owner override in [config.toml](./config.toml) exists only so the setters authorize during simulation.

## Post-execution verification

```bash
cast call 0xeb776E1d4cda95D4155e73c5ceE34b9f7C2EE818 "batcherHash()(bytes32)" --rpc-url <SEPOLIA_RPC>
# Expected: 0x00000000000000000000000004bf2305dc047e9a00ad71c08c9e8dec502091a2
cast call 0xeb776E1d4cda95D4155e73c5ceE34b9f7C2EE818 "unsafeBlockSigner()(address)" --rpc-url <SEPOLIA_RPC>
# Expected: 0x5D2680A041a63376071512eBF6f7fB3380Edad02
```

Record the executed tx hash in the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) under the setBatcherHash / setUnsafeBlockSigner step.
