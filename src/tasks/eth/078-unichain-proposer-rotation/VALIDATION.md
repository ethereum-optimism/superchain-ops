# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonces in [config.toml](./config.toml) (L1PAO 44,
FoundationUpgradeSafe 74, SecurityCouncil 71) and move
only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x232888a8b9ad1c13d8b313bce21056f764c65ecb0a2e0f0bcf0ce24a1fa3be95`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x854ce6b65ab2c2dc3b43f91db7564dfd1193c9dfac5af84da4845a8f57f5b1fb`

Root L1PAO (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) safe transaction hash (identical on both signing paths):
`0x295c6de43f1ca7993a5128d257710c32c3220f6d56c469f36d7758c8a73b84b8`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/078-unichain-proposer-rotation
just simulate-stack eth 078-unichain-proposer-rotation council   # or foundation
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
3. The call trace shows one `setImplementation` on `0x2F12d621a16e2d3285929C9996f478508951dFe4` with `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` and the 40-byte `_args` in the [Understanding Task Calldata](#understanding-task-calldata) table, and nothing else.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the L1PAO
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000002f12d621a16e2d3285929c9996f478508951dfe400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c4b107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d6910000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002827cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9dead00000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the L1PAO (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x2F12d621a16e2d3285929C9996f478508951dFe4` (DisputeGameFactoryProxy) | `setImplementation(uint32,address,bytes)` | `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, `_args = 0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9dead000000000000000000000000000000000003` (anchorStateRegistry \| proposer) |

To verify the payload fingerprints:

```bash
cast calldata "setImplementation(uint32,address,bytes)" 5 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9dead000000000000000000000000000000000003
# Expected: 0xb107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d6910000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002827cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9dead000000000000000000000000000000000003000000000000000000000000000000000000000000000000
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A "nonce()(uint256)" -r $RPC   # 44
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 74
cast call 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 "nonce()(uint256)" -r $RPC   # 71
cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691
cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9d5f0e2912c70771c589cd8bb087ede0dab4afa9a
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/078-unichain-proposer-rotation

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

### Task State Changes

#### `0x2F12d621a16e2d3285929C9996f478508951dFe4` (Unichain DisputeGameFactoryProxy)

- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf7`
  - **Before:** `0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9d5f0e2912c70771c589cd8bb`
  - **After:**  `0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9dead00000000000000000000`
- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf8`
  - **Before:** `0x087ede0dab4afa9a000000000000000000000000000000000000000000000000`
  - **After:**  `0x0000000000000003000000000000000000000000000000000000000000000000`
  - **Summary:** the two data slots of the `gameArgs[5]` bytes value: the first 20 bytes (anchorStateRegistry) are unchanged, the proposer moves to `0xdead000000000000000000000000000000000003`. `gameImpls[5]` and `initBonds[5]` are rewritten with their current values (no diff).

#### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO, root safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `44` → **After:** `45`
  - **Summary:** nonce increment of the root safe. The before-value reflects the nonce state
    override in [config.toml](./config.toml).
- **Key (foundation path):** `0xd9236554b23fd9f561042597e2c7e9bb6b4d45d2f712e3b93aa05dac34cb9616`
- **Key (council path):** `0xb081e1cf563c3282ed672c1742a06c3af6fc6c01ab032b9d049239a33cf7c60a`
  - **Before:** `0` → **After:** `1`
  - **Summary:** `approvedHashes[<child safe>][0x295c6de4…]`, the child safe's approval. Only the
    key of the path being simulated is written. Derive with
    `cast index bytes32 0x295c6de43f1ca7993a5128d257710c32c3220f6d56c469f36d7758c8a73b84b8 $(cast index address <child> 8)`.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe), foundation path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `74` → **After:** `75`
  - **Summary:** nonce increment of the approving child safe.

#### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (SecurityCouncil), council path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `71` → **After:** `72`
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

cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9dead000000000000000000000000000000000003
cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 (unchanged)
cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "initBonds(uint32)(uint256)" 5 -r $RPC   # 0 (unchanged)
```
