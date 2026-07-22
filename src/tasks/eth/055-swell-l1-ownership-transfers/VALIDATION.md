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
> This task is `DRAFT, NOT READY TO SIGN` — it requires Optimism Governance
> approval before signing. The hashes below were generated against the stacked
> simulation (CI simulates the stack 053 → 054 → 055), with the stack-adjusted
> nonces pinned in `config.toml` `stateOverrides`:
> - Standard OP Mainnet L1PAO Safe: **36**  (live 35 + 1: task 053 executes via this Safe)
> - FoundationUpgradeSafe:          **59**  (live 57 + 2: tasks 053 and 054 both nest this Safe)
> - SecurityCouncil:                **60**  (live 58 + 2: tasks 053 and 054 both nest this Safe)
>
> All three Safes are shared across many Mainnet chains. Before signing,
> re-verify the live nonces with `cast call <safe> "nonce()" --rpc-url mainnet`
> and your ledger. If any has advanced — or the set of preceding non-executed
> tasks in the stack changes — bump the corresponding override and re-simulate
> so the hashes below are regenerated.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xf41572e9d18df7837e019c1ee7c4ddded7c1040df0976923d204756e637a87f2`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x17de8262e31d4cc660ae443a1b0b7297cce9727c754bf8e9a8dbca605e1288c4`

## State Changes

The simulation produces three state changes on L1 Mainnet:

---

### `0x4c4710a4ec3f514a492cc6460818c4a6a6269dd6` (Swell ProxyAdmin) — Chain ID: 1923

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x000000000000000000000000a83f1334c6a8daca576dc14020d9d2b1b16a8dfa`
  - **Summary:** Transfer L1 ProxyAdmin ownership to AltLayer's new owner Safe.
  - **Detail:** OpenZeppelin Ownable layout — slot 0 holds the owner. Confirm
    the pre-state with:
    ```bash
    cast call 0x4C4710a4Ec3F514A492CC6460818C4A6A6269dd6 "owner()(address)" --rpc-url mainnet
    # returns 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
    ```

---

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (Standard OP Mainnet L1PAO Safe — parent multisig) — Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `36`
  - **After:**  `37`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump for executing this task. The
    pre-state is 36 (not the live 35) because CI simulates the stack
    053 → 054 → 055, and task 053 consumes one L1PAO nonce ahead of this task.

---

### `0x87690676786cdc8cca75a472e483af7c8f2f0f57` (Swell DisputeGameFactoryProxy) — Chain ID: 1923

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x000000000000000000000000a83f1334c6a8daca576dc14020d9d2b1b16a8dfa`
  - **Summary:** Transfer DisputeGameFactory ownership to AltLayer's new owner Safe.
  - **Detail:** Slot `0x33` is the Ownable owner slot for this contract layout.
    Confirm the pre-state with:
    ```bash
    cast call 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57 "owner()(address)" --rpc-url mainnet
    # returns 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
    ```

The chain's DelayedWETH (`0xdD525E7E8fA35345D30e88018c9925F3C2876107`, v1.5.0)
is post-U16 and not ownable — the `TransferOwners` template logs a "not ownable,
not performing transfer" line for it and produces no state change.

## Task Calldata

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000012000000000000000000000000087690676786cdc8cca75a472e483af7c8f2f0f570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000a83f1334c6a8daca576dc14020d9d2b1b16a8dfa000000000000000000000000000000000000000000000000000000000000000000000000000000004c4710a4ec3f514a492cc6460818c4a6a6269dd60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000a83f1334c6a8daca576dc14020d9d2b1b16a8dfa00000000000000000000000000000000000000000000000000000000
```
