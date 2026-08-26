# Validation

This document can be used to validate the inputs and result of the execution of
the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): the new owner and the chain ID can be
   verified directly in `config.toml` and against the
   [governance post](https://app.notion.com/p/oplabs/EXTERNAL-Maintenance-Upgrade-Proposal-Unichain-ProxyAdmin-Owner-Transition-to-Standard-Optimism-Go-381f153ee16281efad21c307cef7c928).
3. State Changes: see [State Changes](#state-changes) below. They can also be
   reviewed in Tenderly using the link printed by the simulation, and verified
   against the template's `_validate` assertions.

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should
match both the values on your ledger and the values printed to the terminal
when you run the task.

> [!CAUTION]
>
> These hashes assume the pinned nonces below (see `config.toml`). The Unichain
> 3-of-3 and Chain Governor pins are the live on-chain values as of 2026-08-25;
> the FUS and SC pins are live + 1, accounting for task
> `066-soneium-fee-vault-recipient-update` which is stacked before this task:
> - Unichain 3-of-3 Safe:        **10** (live)
> - Unichain Chain Governor:     **19** (live)
> - FoundationUpgradeSafe:       **67** (live 66 + 1, task 066)
> - SecurityCouncil:             **65** (live 64 + 1, task 066)
>
> Before signing, re-verify each live nonce with
> `cast call <safe> "nonce()(uint256)" --rpc-url mainnet`. If any has advanced
> past the values above, bump the override in `config.toml` and re-simulate to
> regenerate these hashes.
>
> ### Unichain Chain Governor Safe (`0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`)
>
> - Domain Hash:  `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `0x28e77c5d683769217491d0641e997b31da6e7af654ec5cd90c6f4fd4771f6197`
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x5e7b347c7dc25fdfb5efbb3ad0745dccf142808f1462123f7e31eea4d3065211`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xc940286479d5287ad41d0c4c41f2b3be5606199fcd702eeb4150454db0debb5f`

## State Changes

The simulation produces three state changes on L1 Ethereum Mainnet (the two
ownership transfers and the root Safe nonce), plus the standard
nested-execution bookkeeping described below.

### Signer safes (nested-execution bookkeeping)

The approving child safe's nonce increments by 1 (Unichain Chain Governor
`19` → `20`, FoundationUpgradeSafe `67` → `68`, or SecurityCouncil `65` → `66`,
per the pinned overrides). During each child safe's approve step, the root
Unichain 3-of-3 also gains an
`approvedHashes[<child safe>][0x853896d548772f2fd70fdea4da6fe3b9597d12fbad422684e3afae2763974390] = 1`
storage write — expect it in the Tenderly state diff of the approval
transactions.

---

### `0x6d5b183f538abb8572f5cd17109c617b994d5833` (Unichain 3-of-3 — parent multisig) — Chain ID: 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `10`
  - **After:**  `11`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump for executing this task.

---

### `0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4` (Unichain ProxyAdmin) — Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x6d5b183f538abb8572f5cd17109c617b994d5833`
  - **After:**  `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **Summary:** Transfer L1 ProxyAdmin ownership to the OP-governed L1PAO.
  - **Detail:** OpenZeppelin Ownable layout — slot 0 holds the owner. The new
    owner matches the governance proposal (the same L1PAO as OP Mainnet).
    Confirm the pre-state with:
    ```bash
    cast storage 0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4 0x0 --rpc-url mainnet
    # returns 0x0000000000000000000000006d5b183f538abb8572f5cd17109c617b994d5833
    cast call 0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4 "owner()(address)" --rpc-url mainnet
    # returns 0x6d5B183F538ABB8572F5cD17109c617b994D5833
    ```

---

### `0x2f12d621a16e2d3285929c9996f478508951dfe4` (Unichain DisputeGameFactoryProxy) — Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x6d5b183f538abb8572f5cd17109c617b994d5833`
  - **After:**  `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **Summary:** Transfer DisputeGameFactory ownership to the OP-governed L1PAO.
  - **Detail:** Slot `0x33` is the Ownable owner slot for this contract layout.
    Confirm the pre-state with:
    ```bash
    cast storage 0x2F12d621a16e2d3285929C9996f478508951dFe4 0x33 --rpc-url mainnet
    # returns 0x0000000000000000000000006d5b183f538abb8572f5cd17109c617b994d5833
    cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "owner()(address)" --rpc-url mainnet
    # returns 0x6d5B183F538ABB8572F5cD17109c617b994D5833
    ```

There is no DelayedWETH state change — Unichain's DelayedWETH
(`0x74ad145aC900F1DD5551F0C9E143314DC4022FCf`) is post-U16 and not ownable, so
there is no ownership to transfer. See [config.toml](./config.toml).

## Post-execution verification

```bash
cast call 0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4 "owner()(address)" --rpc-url mainnet
cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "owner()(address)" --rpc-url mainnet
# Both expected: 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
```

## Task Calldata

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000002f12d621a16e2d3285929c9996f478508951dfe40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a000000000000000000000000000000000000000000000000000000000000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a00000000000000000000000000000000000000000000000000000000
```

The calldata decodes as a `Multicall3.aggregate3Value` with two calls, both
`transferOwnership(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A)`:

1. `0x2F12d621a16e2d3285929C9996f478508951dFe4` (DisputeGameFactoryProxy)
2. `0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4` (ProxyAdmin)

Verify the inner payload by hand with:

```bash
cast calldata-decode "transferOwnership(address)" \
  0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a
# returns 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
```
