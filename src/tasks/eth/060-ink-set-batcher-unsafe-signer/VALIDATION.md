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
> ### FoundationOperationsSafe (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)
>
> - Domain Hash:  `0x2e5ad244d335c45fbace4ebd1736b0fad81b01591a2819baedad311ead5bce76`
> - Message Hash: `0x8a6f21dfb2ab9207f681225cd5daf309651c867f52b6c3b6a9534af37a78f06b`
> - Safe Hash:    `0x4a37ded5e0f9143bc965b7af48ce22ffcad5331994b7f1dd36fd4ba0a0668704`
>
> _Generated with the [config.toml](./config.toml) state overrides (FoundationOperationsSafe **stacked nonce = 120** = on-chain 118 + the two preceding FOS-signed stack tasks 058/059; `SystemConfig.owner` → FOS). Valid only for those overrides — re-run `just simulate` and replace them if the FOS nonce advances or the owner override is removed (after the ownership transfer executes) before signing._
>
> The Domain Hash is deterministic for the FOS on Ethereum mainnet (chainId 1): `keccak256(abi.encode(0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218, 1, 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A))`.

## Understanding Task Calldata

The task batches two `SystemConfig` setters through Multicall3, targeting the Ink mainnet `SystemConfigProxy` (`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`).

Verify the two inner calldata fingerprints:

```bash
# setBatcherHash(bytes32) — OPE batcher left-padded to 32 bytes
cast calldata "setBatcherHash(bytes32)" 0x0000000000000000000000006db6161fc5662450e801398bad62dd9921216b98
# Expected: 0xc9b26f610000000000000000000000006db6161fc5662450e801398bad62dd9921216b98

# setUnsafeBlockSigner(address) — OPE sequencer
cast calldata "setUnsafeBlockSigner(address)" 0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1
# Expected: 0x18d139180000000000000000000000007b322282df45e537e5de76d60e1432db3cf3f8e1
```

The outer Multicall3 `aggregate3` blob is assembled by the framework and printed during simulation; confirm it contains both inner calls above and no others.

## Task State Changes

### `0x62c0a111929fa32cec2f76adba54c16afb6e8364` (SystemConfigProxy) — Chain ID 57073

- `batcherHash()` updates from `0x000000000000000000000000500d7ea63cf2e501dadaa5feec1fc19fe2aa72ac` (Gelato) to `0x0000000000000000000000006db6161fc5662450e801398bad62dd9921216b98` (OPE batcher).
- `unsafeBlockSigner()` updates from `0x7D056B99AA2021864c42E25B4F8cE3BdEAc9463C` (Gelato) to `0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1` (OPE sequencer).

### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (FoundationOperationsSafe)

Nonce increments `120` → `121` (stacked value — see above). (Simulation labels this address `Challenger (GnosisSafe) - Chain ID: 10` — the same Safe is the OP Mainnet challenger in the registry; the contract being modified here is the Ink SystemConfig owner Safe.)

> [!NOTE]
> The `SystemConfig.owner()` slot-`0x33` value (Gelato → FOS) is **not** a state change produced by this task; it is a simulation-only override modelling the post-transfer state (the live owner is still the Gelato Safe `0xBeA2Bc…9Bbb`). It is set outside this repo by the ownership transfer ([PR #1462](https://github.com/ethereum-optimism/superchain-ops/pull/1462)); remove the override once that transfer executes on-chain.

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "batcherHash()(bytes32)" --rpc-url mainnet
# Expected: 0x0000000000000000000000006db6161fc5662450e801398bad62dd9921216b98
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "unsafeBlockSigner()(address)" --rpc-url mainnet
# Expected: 0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1
```
