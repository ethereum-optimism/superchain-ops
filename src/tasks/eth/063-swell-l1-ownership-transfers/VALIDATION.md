# Validation

This document can be used to validate the inputs and result of the execution of
the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): the new owner and the chain ID can be
   verified directly in `config.toml`. The chain's fallback addresses are in
   `addresses.json`.
3. State Changes: see [State Changes](#state-changes) below. They can also be
   reviewed in Tenderly using the link printed by the simulation, and verified
   against the template's `_validate` assertions.

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should
match both the values on your ledger and the values printed to the terminal
when you run the task.

> [!CAUTION]
>
> These hashes assume the pinned nonces below — the live on-chain values as of
> 2026-08-03:
> - Standard mainnet L1PAO Safe: **38**
> - FoundationUpgradeSafe:       **64**
> - SecurityCouncil:             **62**
>
> Before signing, re-verify each live nonce with
> `cast call <safe> "nonce()(uint256)" --rpc-url mainnet`. If any has advanced,
> bump the override in `config.toml` and re-simulate to regenerate these hashes.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x0364ce6ed15a48221acb00ab58095c36be3470f562fa9d2e14890569ced32d9c`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x4a54ec799df3c1909da6d65247f982d38887ce48cd31bb5122762c72e3054d4b`

## State Changes

The simulation produces three state changes on L1 Ethereum Mainnet (the
ownership transfers and the root Safe nonce), plus the standard
nested-execution bookkeeping described below.

### Signer safes (nested-execution bookkeeping)

The approving child safe's nonce increments by 1 (FoundationUpgradeSafe
`64` → `65`, or SecurityCouncil `62` → `63`, per the pinned overrides).
During each child safe's approve step, the root L1PAO also gains an
`approvedHashes[<child safe>][0xca0b43a9238dfeb9fca6b6b3c38369a55917b482ca30562fd6d2bd50979f8e9d] = 1`
storage write — expect it in the Tenderly state diff of the approval
transactions.

---

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (Standard mainnet L1PAO Safe — parent multisig) — Chain ID: 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `38`
  - **After:**  `39`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump for executing this task.

---

### `0x4c4710a4ec3f514a492cc6460818c4a6a6269dd6` (Swell ProxyAdmin) — Chain ID: 1923

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0xa83f1334c6a8daca576dc14020d9d2b1b16a8dfa`
  - **Summary:** Transfer L1 ProxyAdmin ownership to AltLayer's Safe.
  - **Detail:** OpenZeppelin Ownable layout — slot 0 holds the owner. The new
    owner matches the governance proposal and AltLayer's confirmation. Confirm
    the pre-state with:
    ```bash
    cast storage 0x4C4710a4Ec3F514A492CC6460818C4A6A6269dd6 0x0 --rpc-url mainnet
    # returns 0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a
    cast call 0x4C4710a4Ec3F514A492CC6460818C4A6A6269dd6 "owner()(address)" --rpc-url mainnet
    # returns 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
    ```

---

### `0x87690676786cdc8cca75a472e483af7c8f2f0f57` (Swell DisputeGameFactoryProxy) — Chain ID: 1923

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0xa83f1334c6a8daca576dc14020d9d2b1b16a8dfa`
  - **Summary:** Transfer DisputeGameFactory ownership to AltLayer's Safe.
  - **Detail:** Slot `0x33` is the Ownable owner slot for this contract layout.
    Confirm the pre-state with:
    ```bash
    cast storage 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57 0x33 --rpc-url mainnet
    # returns 0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a
    cast call 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57 "owner()(address)" --rpc-url mainnet
    # returns 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
    ```

There is no DelayedWETH state change — the contract is not ownable, so there
is no ownership to transfer. See [config.toml](./config.toml) for the details.

## Task Calldata

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000012000000000000000000000000087690676786cdc8cca75a472e483af7c8f2f0f570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000a83f1334c6a8daca576dc14020d9d2b1b16a8dfa000000000000000000000000000000000000000000000000000000000000000000000000000000004c4710a4ec3f514a492cc6460818c4a6a6269dd60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000a83f1334c6a8daca576dc14020d9d2b1b16a8dfa00000000000000000000000000000000000000000000000000000000
```
