# Validation

This document can be used to validate the inputs and result of the execution of the
transfer transaction which you are signing.

The steps are:

1. [Validate the Addresses](#address-sources)
2. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
3. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
4. State Changes: the template's `_validate` block asserts `SystemConfig.owner() == newOwner`. State changes can also be reviewed in Tenderly via the link printed during simulation.

## Address Sources

| Address | Role | Source |
|---|---|---|
| `0x05C993e60179f28bF649a2Bb5b00b5F4283bD525` | Ink Sepolia `SystemConfigProxy` (target) | [superchain-registry: `superchain/configs/sepolia/ink.toml`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml) (`addresses.SystemConfigProxy`) |
| `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` | Foundation Operations Safe (current owner, signer) | [`src/addresses.toml`](../../../addresses.toml) `[sep].FoundationOperationsSafe` |
| `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` | Foundation Upgrade Safe (`newOwner`) | [`src/addresses.toml`](../../../addresses.toml) `[sep].FoundationUpgradeSafe` |

Note: the superchain-registry's `validation/standard/standard-config-roles-sepolia.toml` does not track the Foundation Safes on Sepolia (the standard Sepolia roles use an EOA), so [`src/addresses.toml`](../../../addresses.toml) is the source of truth for the FOS/FUS addresses here — cross-check it against prior Sepolia tasks signed by these Safes (e.g. `sep/101`–`sep/103`).

Verify the current owner on-chain:

```bash
cast call 0x05C993e60179f28bF649a2Bb5b00b5F4283bD525 "owner()(address)" --rpc-url https://ethereum-sepolia-rpc.publicnode.com
# Expected (pre-execution): 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E (Foundation Operations Safe)
```

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Operations Safe (`0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`)
>
> - Domain Hash:  `0xe84ad8db37faa1651b140c17c70e4c48eaa47a635e0db097ddf4ce1cc14b9ecb`
> - Message Hash: `0x796708675921453be7da6340f434a1d87abbedfbf232aa3aa4881ab16cb1fc38`
> - Safe Hash:    `0xa0f635ed34e5b770bce80b1aee1eb6fedeaac9f3aaf043ab6e544b2a5047eeda`
>
> _Hashes above were generated with the state overrides in `config.toml` (FOS nonce = 14). If the live nonce advances, update the override, re-run `just simulate` and replace these values before signing._

## Understanding Task Calldata

The task calls `SystemConfig.transferOwnership(address)` on the Ink Sepolia `SystemConfigProxy` (`0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`) with the Foundation Upgrade Safe as argument.

Verify the inner calldata fingerprint:

```bash
cast calldata "transferOwnership(address)" 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
# Expected: 0xf2fde38b000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b
```

### Task Calldata

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd5250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b00000000000000000000000000000000000000000000000000000000
```

## Task State Changes

- `SystemConfigProxy.owner()` updates from `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (Foundation Operations Safe) to `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (Foundation Upgrade Safe).
- The Foundation Operations Safe (`0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`) nonce increments by 1.

## Post-execution verification

```bash
cast call 0x05C993e60179f28bF649a2Bb5b00b5F4283bD525 "owner()(address)" --rpc-url https://ethereum-sepolia-rpc.publicnode.com
# Expected: 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
```
