# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe
81), with the SystemConfig owner set to the FoundationUpgradeSafe and sep/112 executed first, and move only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x9f69e99544aee844c3893071f10392f356863d1a2f39a6b644d58d20d33095de`

Safe transaction hash: `0xe16d005c51b2d103119ee28951b8f78508951edaaf6ff2cb6f690729588663ae`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/114-op-sepolia-set-unsafe-signer
just simulate-stack sep 114-op-sepolia-set-unsafe-signer
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, the outer
   `execTransaction`, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   storage writes must match [Task State Changes](#task-state-changes), which also explains the
   simulation's nonce override and sender nonce bump.
3. The call trace shows `setUnsafeBlockSigner` on `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` with the values in the [Understanding Task Calldata](#understanding-task-calldata) table, and one `ConfigUpdate` event (`updateType` 3 `UNSAFE_BLOCK_SIGNER`).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the FoundationUpgradeSafe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002418d13918000000000000000000000000dead00000000000000000000000000002002dead00000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the FoundationUpgradeSafe (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (SystemConfigProxy) | `setUnsafeBlockSigner(address)` | `_unsafeBlockSigner = 0xdead00000000000000000000000000002002dead` |

To verify the payload fingerprints:

```bash
cast calldata "setUnsafeBlockSigner(address)" 0xdead00000000000000000000000000002002dead
# Expected: 0x18d13918000000000000000000000000dead00000000000000000000000000002002dead
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "nonce()(uint256)" -r $RPC   # 81
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "owner()(address)" -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B (after the SystemConfig owner transfer)
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "batcherHash()(bytes32)" -r $RPC   # 0x00000000000000000000000064eda4f93314ecd619bd4f79d8d1f8112a4e6e16 (sep/112 executed)
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/114-op-sepolia-set-unsafe-signer

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (OP Sepolia SystemConfigProxy)

- **Key:** `0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08`
  - **Before:** `0x00000000000000000000000057cacbb0d30b01eb2462e5dc940c161aff3230d3`
  - **After:**  `0x000000000000000000000000dead00000000000000000000000000002002dead`
  - **Summary:** `unsafeBlockSigner` (`keccak256("systemconfig.unsafeblocksigner")`, `UNSAFE_BLOCK_SIGNER_SLOT()`).

#### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `81` → **After:** `82`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "batcherHash()(bytes32)"       -r $RPC   # 0x00000000000000000000000064eda4f93314ecd619bd4f79d8d1f8112a4e6e16 (unchanged)
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "unsafeBlockSigner()(address)" -r $RPC   # 0xdead00000000000000000000000000002002dead
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "owner()(address)"             -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B (unchanged)
```
