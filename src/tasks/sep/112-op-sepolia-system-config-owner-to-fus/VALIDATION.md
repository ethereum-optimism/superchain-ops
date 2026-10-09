# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

This is a plain EOA transaction, so there are no Safe domain or message hashes. What the signer
must check is the destination, the calldata and the signing address.

## For the Signer

1. The transaction goes to `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (OP Sepolia
   `SystemConfigProxy`), on Sepolia (chainId 11155111), with `value = 0`.
2. The calldata is exactly the [Transaction Calldata](#transaction-calldata) below.
3. The signing key resolves to `0xfd1D2e729aE8eEe2E146c033bf4400fE75284301`:

```bash
# Ledger:
cast wallet address --ledger
# Raw private key (prompted):
cast wallet address --interactive
# Foundry keystore:
cast wallet address --account op-sep-sysconfig-owner
# Expected: 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301
```

## For Facilitators and Reviewers

### Transaction Calldata

```
0xf2fde38b000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b
```

### Understanding Transaction Calldata

A single call, no Multicall3 wrapper:

| Target | Function | Arguments |
|---|---|---|
| `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (SystemConfigProxy) | `transferOwnership(address)` (selector `0xf2fde38b`) | `newOwner = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe) |

To verify:

```bash
cast calldata "transferOwnership(address)" 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
# Expected: 0xf2fde38b000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b
```

### Pre-execution checks

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

# Current owner is the EOA, and it has no code.
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "owner()(address)" -r $RPC   # 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301
cast code 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301 -r $RPC                     # 0x

# New owner is the Sepolia FoundationUpgradeSafe (src/addresses.toml), a live Safe.
cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "getThreshold()(uint256)" -r $RPC   # non-zero
cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "getOwners()(address[])" -r $RPC    # non-empty

# Dry run from the EOA: must succeed (empty output, no revert).
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "transferOwnership(address)" 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B --from 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301 -r $RPC
```

Then send the transaction with one of the commands in the [README](./README.md#execution).

### Transaction State Changes

#### `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (OP Sepolia SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x000000000000000000000000fd1d2e729ae8eee2e146c033bf4400fe75284301`
  - **After:**  `0x000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b`
  - **Summary:** `_owner` (OpenZeppelin `OwnableUpgradeable`, slot 51).

One event: `OwnershipTransferred(previousOwner, newOwner)` (topic0
`0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0`) with
`previousOwner = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301` and
`newOwner = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`.

The EOA's account nonce increments by one and it pays the gas (about 36k gas).

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "owner()(address)" -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
cast storage 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 0x33 -r $RPC              # 0x000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b
cast receipt <tx hash> logs -r $RPC                                                 # one OwnershipTransferred log, topics as above
```
