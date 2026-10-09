# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe
79), with the SystemConfig owner set to the FoundationUpgradeSafe, and move only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x8e2b0c9043f84b54493d989392a38587786f97b8ced261a57c0a57c01dac1392`

Safe transaction hash: `0xe4535f56c2f255f641e205fbdc908440fd96179f11cbd4e1e10d57c977e5153f`

## For Signers

```bash
cd src/tasks/sep/112-op-sepolia-set-batcher
just simulate-stack sep 112-op-sepolia-set-batcher
```

The domain and message hashes printed to the terminal must match the ones above
and the ones on your ledger.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the FoundationUpgradeSafe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack`.

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b5380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024c9b26f6100000000000000000000000064eda4f93314ecd619bd4f79d8d1f8112a4e6e1600000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the FoundationUpgradeSafe (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (SystemConfigProxy) | `setBatcherHash(bytes32)` | `_batcherHash = 0x64EDa4F93314ECd619bd4f79D8d1F8112A4E6e16` (left-padded) |

To verify the payload fingerprints:

```bash
cast calldata "setBatcherHash(bytes32)" 0x00000000000000000000000064EDa4F93314ECd619bd4f79D8d1F8112A4E6e16
# Expected: 0xc9b26f6100000000000000000000000064eda4f93314ecd619bd4f79d8d1f8112a4e6e16
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "nonce()(uint256)" -r $RPC   # 79
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "owner()(address)" -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B (after the SystemConfig owner transfer)
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/112-op-sepolia-set-batcher

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (OP Sepolia SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000067`
  - **Before:** `0x0000000000000000000000008f23bb38f531600e5d8fddaaec41f13fab46e98c`
  - **After:**  `0x00000000000000000000000064eda4f93314ecd619bd4f79d8d1f8112a4e6e16`
  - **Summary:** `batcherHash`.

#### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `79` → **After:** `80`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "batcherHash()(bytes32)"       -r $RPC   # 0x00000000000000000000000064eda4f93314ecd619bd4f79d8d1f8112a4e6e16
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "unsafeBlockSigner()(address)" -r $RPC   # 0x57CACBB0d30b01eb2462e5dC940c161aff3230D3 (unchanged)
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "owner()(address)"             -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B (unchanged)
```
