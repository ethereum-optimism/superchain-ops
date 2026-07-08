# Validation

This document can be used to validate the inputs and result of the execution of the transfer transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): the new owner and the chain ID can be verified directly in `config.toml`.
3. State Changes: see [Task State Changes](#task-state-changes) below. They can also be reviewed in Tenderly via the link printed during simulation, and the template's `_validate` block asserts `SystemConfig.owner() == newOwner`.

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationOperationsSafe (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)
>
> - Domain Hash:  `TODO — regenerate with just simulate once the FOS nonce is set to its live value`
> - Message Hash: `TODO`
> - Safe Tx Hash: `TODO`

The domain hash can be independently reproduced with:

```bash
cast keccak $(cast abi-encode "x(bytes32,uint256,address)" \
  0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218 \
  1 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A)
```

## Understanding Task Calldata

The task makes a single call: `SystemConfig.transferOwnership(address)` on the Ink `SystemConfigProxy` (`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`) with the Gelato Safe as argument, wrapped in `Multicall3.aggregate3Value`.

Verify the inner calldata fingerprint:

```bash
cast calldata "transferOwnership(address)" 0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb
# Expected: 0xf2fde38b000000000000000000000000bea2bc852a160b8547273660e22f4f08c2fa9bbb
```

## Task State Changes

### `0x62c0a111929fa32cec2f76adba54c16afb6e8364` (Ink SystemConfigProxy) — Chain ID: 57073

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (FoundationOperationsSafe)
  - **After:** `0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb` (Gelato Safe)
  - **Summary:** `_owner` — slot `0x33` is the OZ `OwnableUpgradeable` owner slot. Ownership reverts to the Ink/Gelato Safe.

### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (FoundationOperationsSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Summary:** nonce — standard Gnosis Safe nonce bump for executing this task.

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "owner()(address)" --rpc-url mainnet
# Expected: 0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb
```
