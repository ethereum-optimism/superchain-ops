# Validation

This document can be used to validate the inputs and result of the execution of
the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): the new owner and the four chain IDs can
   be verified directly in `config.toml`. Dust's fallback addresses are in
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
> These hashes assume the pinned nonces below — one ahead of the live on-chain
> values (read 2026-08-13: L1PAO=40 / FUS=66 / SC=64), accounting for the bump
> from eth/066 (L1PAO-signed):
> - Standard mainnet L1PAO Safe: **41**
> - FoundationUpgradeSafe:       **67**
> - SecurityCouncil:             **65**
>
> Before signing, re-verify each live nonce with
> `cast call <safe> "nonce()(uint256)" --rpc-url mainnet`. The pins apply
> whether or not eth/066 has been signed yet, since the override mimics the
> post-066 state. If a nonce has advanced past the values above, bump the
> override in `config.toml` and re-simulate to regenerate these hashes.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x0038e271761c0265c23ca97deef7dba44d5d5e1c480a719a5183103e3dede1a3`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x8ff5a7f6f876d004d4e6e91c1341970f14e6da3cf6f9aacc9ee7a354a90d1b5a`

## State Changes

The simulation produces nine state changes on L1 Ethereum Mainnet (two
ownership transfers per chain and the root Safe nonce), plus the standard
nested-execution bookkeeping described below.

### Signer safes (nested-execution bookkeeping)

The approving child safe's nonce increments by 1 (FoundationUpgradeSafe
`67` → `68`, or SecurityCouncil `65` → `66`, per the pinned overrides).
During each child safe's approve step, the root L1PAO also gains an
`approvedHashes[<child safe>][0xf149ce6aeebb52e755303e5860fbd6f32c9021a33d1a03262b80bf7bdfdaff41] = 1`
storage write — expect it in the Tenderly state diff of the approval
transactions.

---

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (Standard mainnet L1PAO Safe — parent multisig) — Chain ID: 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `41`
  - **After:**  `42`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump. Starts at 41 because this
    task is sequenced after eth/066, which advances the live nonce 40 → 41.

---

### `0x37ff0ae34dada1a95a4251d10ef7caa868c7ac99` (Metal ProxyAdmin) — Chain ID: 1750

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x4a4962275df8c60a80d3a25faec5aa7de116a746`
  - **Summary:** Transfer Metal L1 ProxyAdmin ownership to the operator's Safe.
  - **Detail:** OpenZeppelin Ownable layout — slot 0 holds the owner.

### `0x7bfff391a2dbbdc68a259792ac9748f50fcde93e` (Metal DisputeGameFactoryProxy) — Chain ID: 1750

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x4a4962275df8c60a80d3a25faec5aa7de116a746`
  - **Summary:** Transfer Metal DisputeGameFactory ownership to the operator's Safe.
  - **Detail:** Slot `0x33` is the Ownable owner slot for this contract layout.

---

### `0x470d87b1dae09a454a43d1fd772a561a03276ab7` (Mode ProxyAdmin) — Chain ID: 34443

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x4a4962275df8c60a80d3a25faec5aa7de116a746`
  - **Summary:** Transfer Mode L1 ProxyAdmin ownership to the operator's Safe.
  - **Detail:** OpenZeppelin Ownable layout — slot 0 holds the owner.

### `0x6f13efadabd9269d6cead22b448d434a1f1b433e` (Mode DisputeGameFactoryProxy) — Chain ID: 34443

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x4a4962275df8c60a80d3a25faec5aa7de116a746`
  - **Summary:** Transfer Mode DisputeGameFactory ownership to the operator's Safe.
  - **Detail:** Slot `0x33` is the Ownable owner slot for this contract layout.

---

### `0xd4ef175b9e72caee9f1fe7660a6ec19009903b49` (Zora ProxyAdmin) — Chain ID: 7777777

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x4a4962275df8c60a80d3a25faec5aa7de116a746`
  - **Summary:** Transfer Zora L1 ProxyAdmin ownership to the operator's Safe.
  - **Detail:** OpenZeppelin Ownable layout — slot 0 holds the owner.

### `0xb0f15106fa1e473ddb39790f197275bc979aa37e` (Zora DisputeGameFactoryProxy) — Chain ID: 7777777

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x4a4962275df8c60a80d3a25faec5aa7de116a746`
  - **Summary:** Transfer Zora DisputeGameFactory ownership to the operator's Safe.
  - **Detail:** Slot `0x33` is the Ownable owner slot for this contract layout.

---

### `0x32c61bd2b7bf8e50f448331705edda99244e7339` (Dust ProxyAdmin) — Chain ID: 55378

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x4a4962275df8c60a80d3a25faec5aa7de116a746`
  - **Summary:** Transfer Dust L1 ProxyAdmin ownership to the operator's Safe.
  - **Detail:** OpenZeppelin Ownable layout — slot 0 holds the owner. Dust is
    not in the superchain-registry, so the simulation output cannot decode
    this contract — verify the address against `addresses.json` and the
    Conduit contracts endpoint
    (https://api.conduit.xyz/file/v1/optimism/contracts/dust-mainnet-0).

### `0xfcd88154a329557499535e7c803f3b3bd7fa1115` (Dust DisputeGameFactoryProxy) — Chain ID: 55378

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Decoded Kind:** `address`
  - **Before:** `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **After:**  `0x4a4962275df8c60a80d3a25faec5aa7de116a746`
  - **Summary:** Transfer Dust DisputeGameFactory ownership to the operator's Safe.
  - **Detail:** Slot `0x33` is the Ownable owner slot for this contract
    layout. Same registry note as the Dust ProxyAdmin above.

There is no DelayedWETH state change on any chain — the contracts are v1.5.0
(post-U16) and not ownable, so there is no ownership to transfer. See
[config.toml](./config.toml) for the details.

## Pre-state verification

Confirm every current owner before signing (each command returns the L1PAO
`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`):

```bash
# Metal (1750)                                  ProxyAdmin / DisputeGameFactoryProxy
cast call 0x37Ff0ae34dadA1A95A4251d10ef7Caa868c7AC99 "owner()(address)" --rpc-url mainnet
cast call 0x7BFfF391A2dbbDc68A259792AC9748F50FcDE93E "owner()(address)" --rpc-url mainnet
# Mode (34443)
cast call 0x470d87b1dae09a454A43D1fD772A561a03276aB7 "owner()(address)" --rpc-url mainnet
cast call 0x6f13EFadABD9269D6cEAd22b448d434A1f1B433E "owner()(address)" --rpc-url mainnet
# Zora (7777777)
cast call 0xD4ef175B9e72cAEe9f1fe7660a6Ec19009903b49 "owner()(address)" --rpc-url mainnet
cast call 0xB0F15106fa1e473Ddb39790f197275BC979Aa37e "owner()(address)" --rpc-url mainnet
# Dust (55378)
cast call 0x32C61Bd2B7bf8E50F448331705eDDA99244e7339 "owner()(address)" --rpc-url mainnet
cast call 0xFcD88154a329557499535E7c803f3B3BD7FA1115 "owner()(address)" --rpc-url mainnet
```

## Post-execution verification

Re-run the eight commands above — each is expected to return the new owner
`0x4a4962275DF8C60a80d3a25faEc5AA7De116A746`.

## Task Calldata

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000002c000000000000000000000000000000000000000000000000000000000000003a000000000000000000000000000000000000000000000000000000000000004800000000000000000000000000000000000000000000000000000000000000560000000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000007200000000000000000000000007bfff391a2dbbdc68a259792ac9748f50fcde93e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a7460000000000000000000000000000000000000000000000000000000000000000000000000000000037ff0ae34dada1a95a4251d10ef7caa868c7ac990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a746000000000000000000000000000000000000000000000000000000000000000000000000000000006f13efadabd9269d6cead22b448d434a1f1b433e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a74600000000000000000000000000000000000000000000000000000000000000000000000000000000470d87b1dae09a454a43d1fd772a561a03276ab70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a74600000000000000000000000000000000000000000000000000000000000000000000000000000000b0f15106fa1e473ddb39790f197275bc979aa37e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a74600000000000000000000000000000000000000000000000000000000000000000000000000000000d4ef175b9e72caee9f1fe7660a6ec19009903b490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a74600000000000000000000000000000000000000000000000000000000000000000000000000000000fcd88154a329557499535e7c803f3b3bd7fa11150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a7460000000000000000000000000000000000000000000000000000000000000000000000000000000032c61bd2b7bf8e50f448331705edda99244e73390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000004a4962275df8c60a80d3a25faec5aa7de116a74600000000000000000000000000000000000000000000000000000000
```
