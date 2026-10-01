# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe
80), with the SystemConfig owner set to the FoundationUpgradeSafe by 111-soneium-minato-system-config-owner-to-fus and move only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x4b6d5d775599d6ff92bb310c4e72fe3c6aabb09d24694af7371d2723e4f11b9e`

Safe transaction hash: `0x0a04e5ac34c2af4e3bb85fe51d686eac51e06077895bb075e05ed2e6f5efea5c`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/115-soneium-minato-set-batcher-unsafe-signer
just simulate-stack sep 115-soneium-minato-set-batcher-unsafe-signer
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
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000004ca9608fef202216bc21d543798ec854539baad30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024c9b26f61000000000000000000000000dead000000000000000000000000000000001001000000000000000000000000000000000000000000000000000000000000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002418d13918000000000000000000000000dead00000000000000000000000000000000100200000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the FoundationUpgradeSafe (selector
`0x174dea71`) containing **2** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` (SystemConfigProxy) | `setBatcherHash(bytes32)` | `_batcherHash = 0xdead000000000000000000000000000000001001` (left-padded) |
| 2 | `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` (SystemConfigProxy) | `setUnsafeBlockSigner(address)` | `_unsafeBlockSigner = 0xdead000000000000000000000000000000001002` |

To verify the payload fingerprints:

```bash
cast calldata "setBatcherHash(bytes32)" 0x000000000000000000000000dead000000000000000000000000000000001001
# Expected: 0xc9b26f61000000000000000000000000dead000000000000000000000000000000001001

cast calldata "setUnsafeBlockSigner(address)" 0xdead000000000000000000000000000000001002
# Expected: 0x18d13918000000000000000000000000dead000000000000000000000000000000001002
```

Each payload appears exactly once and the target twice. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "nonce()(uint256)" -r $RPC   # 80
cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "owner()(address)" -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B (after 111)
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/115-soneium-minato-set-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` (Soneium Minato SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000067`
  - **Before:** `0x000000000000000000000000f0ab0441c8f4b89b561ae685b98c6ad5175e0cab`
  - **After:**  `0x000000000000000000000000dead000000000000000000000000000000001001`
  - **Summary:** `batcherHash`.
- **Key:** `0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08`
  - **Before:** `0x00000000000000000000000055930859cd7003f32a2ba171297408476532e535`
  - **After:**  `0x000000000000000000000000dead000000000000000000000000000000001002`
  - **Summary:** `unsafeBlockSigner` (`keccak256("systemconfig.unsafeblocksigner") - 1`).

The slot `0x33` owner value is a state override standing in for 111, not a change made by this task.

#### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `80` → **After:** `81`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "batcherHash()(bytes32)" -r $RPC        # 0x000000000000000000000000dead000000000000000000000000000000001001
cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "unsafeBlockSigner()(address)" -r $RPC   # 0xdead000000000000000000000000000000001002
cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "owner()(address)" -r $RPC               # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B (unchanged)
```
