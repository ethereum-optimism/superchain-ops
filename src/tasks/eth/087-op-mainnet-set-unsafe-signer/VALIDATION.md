# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe
84), with eth/081 executed first, and move only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xe001da1e50217f5a3733d211f53b8c4f0531048b5a2c8a5aaea6e8bbf2f0414b`

Safe transaction hash: `0xc3016383a6e66f589f965b83a328c2fb7d75468b1c0d3f58413ba184d4f38987`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/087-op-mainnet-set-unsafe-signer
just simulate-stack eth 087-op-mainnet-set-unsafe-signer
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
3. The call trace shows `setUnsafeBlockSigner` on `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` with the values in the [Understanding Task Calldata](#understanding-task-calldata) table, and one `ConfigUpdate` event (`updateType` 3 `UNSAFE_BLOCK_SIGNER`).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the FoundationUpgradeSafe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002418d139180000000000000000000000002bf56397f5cad2e9d432c18283acb991ea7063c500000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the FoundationUpgradeSafe (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (SystemConfigProxy) | `setUnsafeBlockSigner(address)` | `_unsafeBlockSigner = 0x2BF56397f5cAD2e9d432c18283Acb991Ea7063C5` |

To verify the payload fingerprints:

```bash
cast calldata "setUnsafeBlockSigner(address)" 0x2BF56397f5cAD2e9d432c18283Acb991Ea7063C5
# Expected: 0x18d139180000000000000000000000002bf56397f5cad2e9d432c18283acb991ea7063c5
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 84
cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "owner()(address)" -r $RPC   # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "batcherHash()(bytes32)" -r $RPC   # 0x000000000000000000000000cdf8af38e013fcc1b2d0b7d00fb7671523d4b825 (eth/081 executed)
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/087-op-mainnet-set-unsafe-signer

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (OP Mainnet SystemConfigProxy)

- **Key:** `0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08`
  - **Before:** `0x000000000000000000000000aaaa45d9549eda09e70937013520214382ffc4a2`
  - **After:**  `0x0000000000000000000000002bf56397f5cad2e9d432c18283acb991ea7063c5`
  - **Summary:** `unsafeBlockSigner` (`keccak256("systemconfig.unsafeblocksigner")`, `UNSAFE_BLOCK_SIGNER_SLOT()`).

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `84` → **After:** `85`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "batcherHash()(bytes32)"       -r $RPC   # 0x000000000000000000000000cdf8af38e013fcc1b2d0b7d00fb7671523d4b825 (unchanged)
cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "unsafeBlockSigner()(address)" -r $RPC   # 0x2BF56397f5cAD2e9d432c18283Acb991Ea7063C5
cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "owner()(address)"             -r $RPC   # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (unchanged)
```
