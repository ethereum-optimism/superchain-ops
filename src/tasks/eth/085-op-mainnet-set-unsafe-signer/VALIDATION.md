# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe
82), with eth/079 executed first, and move only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x67729a82f2ef4c35cc6822009ab9c9d06e4750c31c35bcef7d5306e39e8a064a`

Safe transaction hash: `0xccd5dc052df56aec7ac11a73c040e13b1d53e6bbee64ec6b1f2092ccd2c98b07`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/085-op-mainnet-set-unsafe-signer
just simulate-stack eth 085-op-mainnet-set-unsafe-signer
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
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002418d13918000000000000000000000000dead00000000000000000000000000002002dead00000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the FoundationUpgradeSafe (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (SystemConfigProxy) | `setUnsafeBlockSigner(address)` | `_unsafeBlockSigner = 0xdead00000000000000000000000000002002dead` |

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
RPC=https://ethereum-rpc.publicnode.com

cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 82
cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "owner()(address)" -r $RPC   # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "batcherHash()(bytes32)" -r $RPC   # 0x000000000000000000000000dead00000000000000000000000000002001dead (eth/079 executed)
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/085-op-mainnet-set-unsafe-signer

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (OP Mainnet SystemConfigProxy)

- **Key:** `0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08`
  - **Before:** `0x000000000000000000000000aaaa45d9549eda09e70937013520214382ffc4a2`
  - **After:**  `0x000000000000000000000000dead00000000000000000000000000002002dead`
  - **Summary:** `unsafeBlockSigner` (`keccak256("systemconfig.unsafeblocksigner")`, `UNSAFE_BLOCK_SIGNER_SLOT()`).

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `82` → **After:** `83`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "batcherHash()(bytes32)"       -r $RPC   # 0x000000000000000000000000dead00000000000000000000000000002001dead (unchanged)
cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "unsafeBlockSigner()(address)" -r $RPC   # 0xdead00000000000000000000000000002002dead
cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "owner()(address)"             -r $RPC   # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (unchanged)
```
