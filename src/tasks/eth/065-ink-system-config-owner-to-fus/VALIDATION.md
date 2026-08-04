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
> ### Foundation Operations Safe (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)
>
> - Domain Hash:  `0x2e5ad244d335c45fbace4ebd1736b0fad81b01591a2819baedad311ead5bce76`
> - Message Hash: `0x3472dd91fd35705f651475c82f250586ac5d8c2cf85e5e3af44cdc81a8c13412`
> - Safe Hash:    `0x0ad3b377a348cc0c7e5cac8c8a445fa0834a60202a80838f28b5066a9621049d`
>
> _Hashes above were generated with the state overrides in `config.toml` (FOS nonce = 121). If the live nonce advances, update the override, re-run `just simulate` and replace these values before signing._

## Understanding Task Calldata

The task calls `SystemConfig.transferOwnership(address)` on the Ink Mainnet `SystemConfigProxy` (`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`) with the Foundation Upgrade Safe as argument.

Verify the inner calldata fingerprint:

```bash
cast calldata "transferOwnership(address)" 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
# Expected: 0xf2fde38b000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d92
```

### Task Calldata

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e83640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d9200000000000000000000000000000000000000000000000000000000
```

## Task State Changes

- `SystemConfigProxy.owner()` updates from `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (Foundation Operations Safe) to `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Upgrade Safe).
- The Foundation Operations Safe (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`) nonce increments by 1.

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "owner()(address)" --rpc-url <MAINNET_RPC>
# Expected: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
```
