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
> - Domain Hash:  `0xc06101531f2357f3ba430a815de8fdd45dd0ddabefc271fa233980142b45a43e`
> - Message Hash: `0xfa4c003b231de240a3682866843d7bc96482f9f1d321cb8845754f406a104e74`
> - Safe Tx Hash: `0x776a15ad8354b946b04c7a2f7f7f09128ba5ebb2bc3a455f27a64665f50213fa`
>
> _Hashes above were generated with the Safe nonce pinned to 4 via the
> `stateOverrides` in `config.toml` (on-chain value at task creation). If the
> Safe nonce advances before signing, bump the override, re-run
> `just simulate`, and replace these values._

The domain hash can be independently reproduced with:

```bash
cast keccak $(cast abi-encode "x(bytes32,uint256,address)" \
  0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218 \
  11155111 0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb)
# Expected: 0xc06101531f2357f3ba430a815de8fdd45dd0ddabefc271fa233980142b45a43e
```

## Understanding Task Calldata

The task makes a single call: `SystemConfig.transferOwnership(address)` on the
Ink Sepolia `SystemConfigProxy` (`0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`)
with the new owner as argument, wrapped in `Multicall3.aggregate3Value`.

Verify the inner calldata fingerprint:

```bash
cast calldata "transferOwnership(address)" 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E
# Expected: 0xf2fde38b000000000000000000000000837de453ad5f21e89771e3c06239d8236c0efd5e
```

### Task Calldata

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd5250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000837de453ad5f21e89771e3c06239d8236c0efd5e00000000000000000000000000000000000000000000000000000000
```

## Task State Changes

The simulation produces two state changes on L1 Sepolia:

---

### `0x05c993e60179f28bf649a2bb5b00b5f4283bd525` (Ink Sepolia SystemConfigProxy) - Chain ID: 763373

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`
  - **After:** `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`
  - **Summary:** `_owner`
  - **Detail:** Slot `0x33` is the OpenZeppelin `OwnableUpgradeable` owner slot.
    Ownership moves from the Ink-controlled Safe to the Sepolia
    `FoundationOperationsSafe`. Confirm the pre-state with:
    ```bash
    cast storage 0x05C993e60179f28bF649a2Bb5b00b5F4283bD525 0x33 --rpc-url sepolia
    # returns 0x000000000000000000000000bea2bc852a160b8547273660e22f4f08c2fa9bbb
    ```

---

### `0xbea2bc852a160b8547273660e22f4f08c2fa9bbb` (current SystemConfig owner Safe) - Chain ID: 1135

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `4`
  - **After:** `5`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump for executing this task.
    Note: the simulation output labels this address `Challenger (GnosisSafe) -
    Chain ID: 1135` because the same Safe also serves as the Challenger for
    Lisk (chainId 1135) in the SuperchainAddressRegistry; the contract being
    modified here is the Ink Sepolia SystemConfig owner Safe on L1 Sepolia.

## Post-execution verification

```bash
cast call 0x05C993e60179f28bF649a2Bb5b00b5F4283bD525 "owner()(address)" --rpc-url sepolia
# Expected: 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E
```
