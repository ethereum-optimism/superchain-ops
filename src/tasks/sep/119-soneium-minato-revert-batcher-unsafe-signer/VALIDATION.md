# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe
84, shared with the foundation approval of 118), with the SystemConfig owner set to the FoundationUpgradeSafe and move only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x5d8f57659aeaf10798f1207434994c17ec3a3c861f79d2563062ea3b2b666a6a`

Safe transaction hash: `0x1ae29d8bd77629fa7316c9c4b491c77c49254e565dd145a186dd93bb3fad0ff8`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/119-soneium-minato-revert-batcher-unsafe-signer
just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, the outer
   `execTransaction`, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes), and
   nothing else.
3. The call trace shows `setBatcherHash` and `setUnsafeBlockSigner` on `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` with the values in the [Understanding Task Calldata](#understanding-task-calldata) table, and two `ConfigUpdate` events (`updateType` 0 `BATCHER` and 3 `UNSAFE_BLOCK_SIGNER`).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the FoundationUpgradeSafe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate` (see step 2 above).

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000004ca9608fef202216bc21d543798ec854539baad30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024c9b26f61000000000000000000000000f0ab0441c8f4b89b561ae685b98c6ad5175e0cab000000000000000000000000000000000000000000000000000000000000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002418d1391800000000000000000000000055930859cd7003f32a2ba171297408476532e53500000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the FoundationUpgradeSafe (selector
`0x174dea71`) containing **2** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` (SystemConfigProxy) | `setBatcherHash(bytes32)` | `_batcherHash = 0xF0AB0441c8f4B89b561aE685B98c6aD5175e0CAB` (left-padded) |
| 2 | `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` (SystemConfigProxy) | `setUnsafeBlockSigner(address)` | `_unsafeBlockSigner = 0x55930859CD7003F32A2ba171297408476532E535` |

To verify the payload fingerprints:

```bash
cast calldata "setBatcherHash(bytes32)" 0x000000000000000000000000f0ab0441c8f4b89b561ae685b98c6ad5175e0cab
# Expected: 0xc9b26f61000000000000000000000000f0ab0441c8f4b89b561ae685b98c6ad5175e0cab

cast calldata "setUnsafeBlockSigner(address)" 0x55930859CD7003F32A2ba171297408476532E535
# Expected: 0x18d1391800000000000000000000000055930859cd7003f32a2ba171297408476532e535
```

Each payload appears exactly once and the target twice. The calldata is the one of 117 with
Sony's batcher and unsafe block signer in place of the OP Enterprise ones. To decode the full
calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "nonce()(uint256)" -r $RPC   # 84 (118 not executed)
cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "owner()(address)" -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "batcherHash()(bytes32)" -r $RPC        # 0x0000000000000000000000002fe55aa59d58e7c3cb333c652e0fdd9b6d4f3541 (after 117)
cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "unsafeBlockSigner()(address)" -r $RPC   # 0xA657d31425BC40068032Ec4433D781099Ed9EE3F (after 117)
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/119-soneium-minato-revert-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` (Soneium Minato SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000067`
  - **Before:** `0x0000000000000000000000002fe55aa59d58e7c3cb333c652e0fdd9b6d4f3541`
  - **After:**  `0x000000000000000000000000f0ab0441c8f4b89b561ae685b98c6ad5175e0cab`
  - **Summary:** `batcherHash`.
- **Key:** `0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08`
  - **Before:** `0x000000000000000000000000a657d31425bc40068032ec4433d781099ed9ee3f`
  - **After:**  `0x00000000000000000000000055930859cd7003f32a2ba171297408476532e535`
  - **Summary:** `unsafeBlockSigner` (`keccak256("systemconfig.unsafeblocksigner") - 1`).

The before-values and the slot `0x33` owner are state overrides standing in for the Safe UI
transfer and 117, not changes made by this task.

#### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `84` → **After:** `85`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "batcherHash()(bytes32)" -r $RPC        # 0x000000000000000000000000f0ab0441c8f4b89b561ae685b98c6ad5175e0cab
cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "unsafeBlockSigner()(address)" -r $RPC   # 0x55930859CD7003F32A2ba171297408476532E535
cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "owner()(address)" -r $RPC               # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B (unchanged)
```
