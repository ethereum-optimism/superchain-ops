# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonces in [config.toml](./config.toml) (L1PAO 47,
FoundationUpgradeSafe 78, SecurityCouncil 74) and move
only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x12342259ec5a7f58ed7320e4d98c5b7cd12d578a34cad90475513724632be30d`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xa9603532f02f4dbd6892854e1bbf73d81b591a8027841426076b5f1b5f475749`

Root L1PAO (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) safe transaction hash (identical on both signing paths):
`0x88ea20aed60e3c32d53a1c2c3809419950eb88b2417aa2c2e52042fa6974c2d5`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/082-soneium-proposer-rotation
just simulate-stack eth 082-soneium-proposer-rotation council   # or foundation
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
3. The call trace shows one `setImplementation` on `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` with `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` and the 40-byte `_args` in the [Understanding Task Calldata](#understanding-task-calldata) table, and nothing else.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the L1PAO
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000512a3d2c7a43bd9261d2b8e8c9c70d4bd4d503c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c4b107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d691000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000284890928941e62e273da359374b105f803329f473dead00000000000000000000000000000000100300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the L1PAO (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` (DisputeGameFactoryProxy) | `setImplementation(uint32,address,bytes)` | `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, `_args = 0x4890928941e62e273da359374b105f803329f473dead000000000000000000000000000000001003` (anchorStateRegistry \| proposer) |

To verify the payload fingerprints:

```bash
cast calldata "setImplementation(uint32,address,bytes)" 5 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 0x4890928941e62e273da359374b105f803329f473dead000000000000000000000000000000001003
# Expected: 0xb107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d691000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000284890928941e62e273da359374b105f803329f473dead000000000000000000000000000000001003000000000000000000000000000000000000000000000000
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A "nonce()(uint256)" -r $RPC   # 47
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 78
cast call 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 "nonce()(uint256)" -r $RPC   # 74
cast call 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691
cast call 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0x4890928941e62e273da359374b105f803329f473400c164c4a8ca84385b70eed6eb03ea847c8e1b8
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/082-soneium-proposer-rotation

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

### Task State Changes

#### `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0` (Soneium DisputeGameFactoryProxy)

- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf7`
  - **Before:** `0x4890928941e62e273da359374b105f803329f473400c164c4a8ca84385b70eed`
  - **After:**  `0x4890928941e62e273da359374b105f803329f473dead00000000000000000000`
- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf8`
  - **Before:** `0x6eb03ea847c8e1b8000000000000000000000000000000000000000000000000`
  - **After:**  `0x0000000000001003000000000000000000000000000000000000000000000000`
  - **Summary:** the two data slots of the `gameArgs[5]` bytes value: the first 20 bytes (anchorStateRegistry) are unchanged, the proposer moves to `0xdead000000000000000000000000000000001003`. `gameImpls[5]` and `initBonds[5]` are rewritten with their current values (no diff).

#### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO, root safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `47` → **After:** `48`
  - **Summary:** nonce increment of the root safe. The before-value reflects the nonce state
    override in [config.toml](./config.toml).
- **Key (foundation path):** `0x2022bc0c5b64b3ef4e80b433d97a71a02dd7ee5de7e452f8cddba8c53fcaad7a`
- **Key (council path):** `0x46b1bbcee3893eed37baa6c0e172281b59c77a552a91d8995cd8f06a53995cd9`
  - **Before:** `0` → **After:** `1`
  - **Summary:** `approvedHashes[<child safe>][0x88ea20ae…]`, the child safe's approval. Only the
    key of the path being simulated is written. Derive with
    `cast index bytes32 0x88ea20aed60e3c32d53a1c2c3809419950eb88b2417aa2c2e52042fa6974c2d5 $(cast index address <child> 8)`.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe), foundation path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `78` → **After:** `79`
  - **Summary:** nonce increment of the approving child safe.

#### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (SecurityCouncil), council path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `74` → **After:** `75`
  - **Summary:** nonce increment of the approving child safe.

#### `0x24424336F04440b1c28685a38303aC33C9D14a25` (SecurityCouncil LivenessGuard), council path

- **Key:** `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Summary:** `lastLive[0xca11bde05977b3631167028862bE2a173976CA11]` set to the simulation timestamp, a simulation
    artifact (the simulation makes Multicall3 the sole signer of the child safe).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0x4890928941e62e273da359374b105f803329f473dead000000000000000000000000000000001003
cast call 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 (unchanged)
cast call 0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0 "initBonds(uint32)(uint256)" 5 -r $RPC   # 0 (unchanged)
```
