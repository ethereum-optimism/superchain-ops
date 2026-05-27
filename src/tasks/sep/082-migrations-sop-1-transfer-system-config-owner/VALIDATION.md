# Validation

This document can be used to validate the inputs and result of the execution of the
transfer transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's `_validate` block asserts `SystemConfig.owner() == newOwner`. State changes can also be reviewed in Tenderly via the link printed during simulation.

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Safe A (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`) — Partner-impersonating, OPE-controlled
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0x715b71ba25a947940252fe5586460e786db8befe52ee5d9de593569476020d87`
>
> _Hashes above were generated with the state overrides in `config.toml` (Safe A nonce = 1). If those overrides change, re-run `just simulate` and replace these values before signing._

## Understanding Task Calldata

The task calls `SystemConfig.transferOwnership(address)` on the `migrations-sop-1` `SystemConfigProxy` (`0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`) with the new owner as argument.

Verify the inner calldata fingerprint:

```bash
cast calldata "transferOwnership(address)" 0xb3228B623da92283280C87aB8019A405967A2B8f
# Expected: 0xf2fde38b000000000000000000000000b3228b623da92283280c87ab8019a405967a2b8f
```

### Task Calldata

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000c771958af69d4fa44dec2555c41c48800ca1f9fc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000b3228b623da92283280c87ab8019a405967a2b8f00000000000000000000000000000000000000000000000000000000
```

## Task State Changes

- `SystemConfigProxy.owner()` updates from `0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9` (Safe A) to `0xb3228B623da92283280C87aB8019A405967A2B8f` (OPE Receiving Safe / Safe B).
- Safe A (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`) nonce increments by 1.

## Post-execution verification

```bash
cast call 0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc "owner()(address)" --rpc-url <SEPOLIA_RPC>
# Expected: 0xb3228B623da92283280C87aB8019A405967A2B8f
```

Record the executed tx hash in the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) under the SystemConfig.transferOwnership step.
