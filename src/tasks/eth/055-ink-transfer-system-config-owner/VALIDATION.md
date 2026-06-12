# Validation

This document can be used to validate the inputs and result of the execution of
the transfer transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): the new owner and the chain ID can be
   verified directly in `config.toml`.
3. State Changes: see [Task State Changes](#task-state-changes) below. They can
   also be reviewed in Tenderly via the link printed during simulation, and the
   template's `_validate` block asserts `SystemConfig.owner() == newOwner`.

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both
the values on your ledger and the values printed to the terminal when you run
the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Current owner Safe (`0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`)
>
> - Domain Hash:  `0xbe8c8ff5b263aabfa5957a21cfff3c301b7fe41d5c89b2189c54dba8c9251189`
> - Message Hash: `0x5a62546e219f9e6cd2dfddff4f74a3f3b9a824f0385996f67aff2de7331cd849`
> - Safe Tx Hash: `0xfca1e2c5bd605ec22e9d16d4108fd7f65968542054b41d9d677e1368664f20be`
>
> _Hashes above were generated with the Safe nonce pinned to 50 via the
> `stateOverrides` in `config.toml` (on-chain value at task creation). If the
> Safe nonce advances before signing, bump the override, re-run
> `just simulate`, and replace these values._

The domain hash can be independently reproduced with:

```bash
cast keccak $(cast abi-encode "x(bytes32,uint256,address)" \
  0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218 \
  1 0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb)
# Expected: 0xbe8c8ff5b263aabfa5957a21cfff3c301b7fe41d5c89b2189c54dba8c9251189
```

## Understanding Task Calldata

The task makes a single call: `SystemConfig.transferOwnership(address)` on the
Ink `SystemConfigProxy` (`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`) with the
new owner as argument, wrapped in `Multicall3.aggregate3Value`.

Verify the inner calldata fingerprint:

```bash
cast calldata "transferOwnership(address)" 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
# Expected: 0xf2fde38b0000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a
```

### Task Calldata

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e83640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a00000000000000000000000000000000000000000000000000000000
```

## Task State Changes

The simulation produces two state changes on L1 mainnet:

---

### `0x62c0a111929fa32cec2f76adba54c16afb6e8364` (Ink SystemConfigProxy) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`
  - **After:** `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`
  - **Summary:** `_owner`
  - **Detail:** Slot `0x33` is the OpenZeppelin `OwnableUpgradeable` owner slot.
    Ownership moves from the Ink-controlled Safe to the
    `FoundationOperationsSafe`. Confirm the pre-state with:
    ```bash
    cast storage 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 0x33 --rpc-url mainnet
    # returns 0x000000000000000000000000bea2bc852a160b8547273660e22f4f08c2fa9bbb
    ```

---

### `0xbea2bc852a160b8547273660e22f4f08c2fa9bbb` (current SystemConfig owner Safe) - Chain ID: 1135

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `50`
  - **After:** `51`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump for executing this task.
    Note: the simulation output labels this address `Challenger (GnosisSafe) -
    Chain ID: 1135` because the same Safe also serves as the Challenger for
    Lisk (chainId 1135) in the SuperchainAddressRegistry; the contract being
    modified here is the Ink SystemConfig owner Safe on L1 mainnet.

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "owner()(address)" --rpc-url mainnet
# Expected: 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
```
