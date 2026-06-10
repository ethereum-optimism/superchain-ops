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
> Pinned at the following nonces (see `config.toml` `stateOverrides`):
> - Standard Sepolia L1PAO Safe: **50**
> - FoundationUpgradeSafe:       **70**
> - SecurityCouncil:              **64**
>
> All three Safes are shared across many Sepolia chains. Before signing,
> re-verify the live nonces with
> `cast call <safe> "nonce()" --rpc-url sepolia` and your ledger. If any has
> advanced, bump the corresponding override and re-simulate so the hashes
> below are regenerated.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x89cbeea9876c8cab2a5f4787f8085e3722a3f1b5ce6794b7f374fba4965779b6`
>
> ### SecurityCouncil (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xb6310d4fc3859d290255c55c307a10cb805e5ff6f985b5bada1725f3504674dd`

## State Changes

The simulation produces three state changes on L1 Sepolia:

---

### `0x1eb2ffc903729a0f03966b917003800b145f56e2` (Standard Sepolia L1PAO Safe — parent multisig) — Chain ID: 11155111

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `50`
  - **After:**  `51`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump for executing this task.

---

### `0x2f3369b81c2b6e1e80a98f7de44be8cfff314db0` (Osaki ProxyAdmin) — Chain ID: 9111973

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x1eb2ffc903729a0f03966b917003800b145f56e2`
  - **After:**  `0xfb0f8937a0d6999c67e8a01310ebf7fe1859205f`
  - **Summary:** Transfer L1 ProxyAdmin ownership to the new owner Safe.
  - **Detail:** OpenZeppelin Ownable layout — slot 0 holds the owner. Confirm
    the pre-state with:
    ```bash
    cast storage 0x2f3369b81c2b6e1e80a98f7de44be8cfff314db0 0x0 --rpc-url sepolia
    # returns 0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2
    cast call 0x2f3369b81c2b6e1e80a98f7de44be8cfff314db0 "owner()(address)" --rpc-url sepolia
    # returns 0x1Eb2fFc903729a0F03966B917003800b145F56E2
    ```

---

### `0xfa695fc017d374cfa2b1dcbd3e4617a9c3891dda` (Osaki DisputeGameFactoryProxy) — Chain ID: 9111973

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x1eb2ffc903729a0f03966b917003800b145f56e2`
  - **After:**  `0xfb0f8937a0d6999c67e8a01310ebf7fe1859205f`
  - **Summary:** Transfer DisputeGameFactory ownership to the new owner Safe.
  - **Detail:** Slot `0x33` is the Ownable owner slot for this contract layout.
    Confirm the pre-state with:
    ```bash
    cast storage 0xfa695fc017d374cfa2b1dcbd3e4617a9c3891dda 0x33 --rpc-url sepolia
    # returns 0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2
    cast call 0xfa695fc017d374cfa2b1dcbd3e4617a9c3891dda "owner()(address)" --rpc-url sepolia
    # returns 0x1Eb2fFc903729a0F03966B917003800b145F56E2
    ```

The chain's DelayedWETH (`0xe7de4b389e26decdb46907f8204e12680b678b1c`, v1.5.0)
is post-U16 and not ownable — the `TransferOwners` template logs a "not ownable,
not performing transfer" line for it and produces no state change.

## Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000120000000000000000000000000fa695fc017d374cfa2b1dcbd3e4617a9c3891dda0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000fb0f8937a0d6999c67e8a01310ebf7fe1859205f000000000000000000000000000000000000000000000000000000000000000000000000000000002f3369b81c2b6e1e80a98f7de44be8cfff314db00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000fb0f8937a0d6999c67e8a01310ebf7fe1859205f00000000000000000000000000000000000000000000000000000000
```
