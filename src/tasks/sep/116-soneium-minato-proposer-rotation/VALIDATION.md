# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonces in [config.toml](./config.toml) (L1PAO 59,
FoundationUpgradeSafe 81, SecurityCouncil 73) and move
only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x373e2496ff973ec634fa328936d0c560b3c2a550e366ddea68b96e12fb387fb5`
>
> ### SecurityCouncil (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xf43450f52bb5bcbe7b76955ae5f8ee37715cbd10834ca419ff72e74e20476e46`

Root L1PAO (`0x1Eb2fFc903729a0F03966B917003800b145F56E2`) safe transaction hash (identical on both signing paths):
`0xe2ff865c3164096a10d964a451e52f5a5d1ff1c5651751a5ff8cd45755a057b1`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/116-soneium-minato-proposer-rotation
just simulate-stack sep 116-soneium-minato-proposer-rotation council   # or foundation
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, the outer
   `execTransaction` that the child safe sends to the L1PAO, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes), and
   nothing else.
3. The call trace shows one `setImplementation` on `0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01` with `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` and the 40-byte `_args` in the [Understanding Task Calldata](#understanding-task-calldata) table, and nothing else.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the L1PAO
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000b3ad2c38e6e0640d7ce6aa952ab3a60e81bf7a0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c4b107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d6910000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002890066735ee774b405c4f54bfec05b07f16d67188dead00000000000000000000000000000000100300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the L1PAO (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01` (DisputeGameFactoryProxy) | `setImplementation(uint32,address,bytes)` | `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, `_args = 0x90066735ee774b405c4f54bfec05b07f16d67188dead000000000000000000000000000000001003` (anchorStateRegistry \| proposer) |

To verify the payload fingerprints:

```bash
cast calldata "setImplementation(uint32,address,bytes)" 5 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 0x90066735ee774b405c4f54bfec05b07f16d67188dead000000000000000000000000000000001003
# Expected: 0xb107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d6910000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002890066735ee774b405c4f54bfec05b07f16d67188dead000000000000000000000000000000001003000000000000000000000000000000000000000000000000
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x1Eb2fFc903729a0F03966B917003800b145F56E2 "nonce()(uint256)" -r $RPC   # 59
cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "nonce()(uint256)" -r $RPC   # 81
cast call 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 "nonce()(uint256)" -r $RPC   # 73
cast call 0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691
cast call 0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0x90066735ee774b405c4f54bfec05b07f16d67188a759a2c80ec4c6421829862da30dd34436114502
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/116-soneium-minato-proposer-rotation

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

### Task State Changes

#### `0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01` (Soneium Minato DisputeGameFactoryProxy)

- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf7`
  - **Before:** `0x90066735ee774b405c4f54bfec05b07f16d67188a759a2c80ec4c6421829862d`
  - **After:**  `0x90066735ee774b405c4f54bfec05b07f16d67188dead00000000000000000000`
- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf8`
  - **Before:** `0xa30dd34436114502000000000000000000000000000000000000000000000000`
  - **After:**  `0x0000000000001003000000000000000000000000000000000000000000000000`
  - **Summary:** the two data slots of the `gameArgs[5]` bytes value: the first 20 bytes (anchorStateRegistry) are unchanged, the proposer moves to `0xdead000000000000000000000000000000001003`. `gameImpls[5]` and `initBonds[5]` are rewritten with their current values (no diff).

#### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO, root safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `59` → **After:** `60`
  - **Summary:** nonce increment of the root safe. The before-value reflects the nonce state
    override in [config.toml](./config.toml).
- **Key (foundation path):** `0x7ccae1db45bc39058d142983ed33dca086aed86b00649948dc8faf6efdb692ac`
- **Key (council path):** `0x0efd48a0bc6c977611fe38132f34dc25abd384a50f0e1f11956584b52fc9f7e4`
  - **Before:** `0` → **After:** `1`
  - **Summary:** `approvedHashes[<child safe>][0xe2ff865c…]`, the child safe's approval. Only the
    key of the path being simulated is written. Derive with
    `cast index bytes32 0xe2ff865c3164096a10d964a451e52f5a5d1ff1c5651751a5ff8cd45755a057b1 $(cast index address <child> 8)`.

#### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe), foundation path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `81` → **After:** `82`
  - **Summary:** nonce increment of the approving child safe.

#### `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (SecurityCouncil), council path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `73` → **After:** `74`
  - **Summary:** nonce increment of the approving child safe.

#### `0xc26977310bC89DAee5823C2e2a73195E85382cC7` (SecurityCouncil LivenessGuard), council path

- **Key:** `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Summary:** `lastLive[0xca11bde05977b3631167028862bE2a173976CA11]` set to the simulation timestamp, a simulation
    artifact (the simulation makes Multicall3 the sole signer of the child safe).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0x90066735ee774b405c4f54bfec05b07f16d67188dead000000000000000000000000000000001003
cast call 0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 (unchanged)
cast call 0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01 "initBonds(uint32)(uint256)" 5 -r $RPC   # 0 (unchanged)
```
