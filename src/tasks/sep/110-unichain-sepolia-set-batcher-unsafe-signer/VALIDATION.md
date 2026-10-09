# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe
77) and move only if that nonce moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x3d99ff363535f16f990d496ca0c5328324cf92d7692aa4ba5bc8f04dcf35cc87`

Safe transaction hash: `0x03a2d98a92d99cb19fe1211e09dd99ef0daa418c01268975b9a75247a80382a4`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/110-unichain-sepolia-set-batcher-unsafe-signer
just simulate-stack sep 110-unichain-sepolia-set-batcher-unsafe-signer
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
3. The call trace shows `setBatcherHash` and `setUnsafeBlockSigner` on `0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D` with the values in the [Understanding Task Calldata](#understanding-task-calldata) table, and two `ConfigUpdate` events (`updateType` 0 `BATCHER` and 3 `UNSAFE_BLOCK_SIGNER`).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the FoundationUpgradeSafe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000120000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024c9b26f61000000000000000000000000f10b9b33ae8da0581e08ab7ca9ece394301843a900000000000000000000000000000000000000000000000000000000000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002418d1391800000000000000000000000023449eae2bc890db1649aa3071b0e6a9aa97433b00000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the FoundationUpgradeSafe (selector
`0x174dea71`) containing **2** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D` (SystemConfigProxy) | `setBatcherHash(bytes32)` | `_batcherHash = 0xf10b9B33Ae8da0581E08AB7cA9eCE394301843A9` (left-padded) |
| 2 | `0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D` (SystemConfigProxy) | `setUnsafeBlockSigner(address)` | `_unsafeBlockSigner = 0x23449Eae2BC890db1649AA3071b0e6A9Aa97433b` |

To verify the payload fingerprints:

```bash
cast calldata "setBatcherHash(bytes32)" 0x000000000000000000000000f10b9B33Ae8da0581E08AB7cA9eCE394301843A9
# Expected: 0xc9b26f61000000000000000000000000f10b9b33ae8da0581e08ab7ca9ece394301843a9

cast calldata "setUnsafeBlockSigner(address)" 0x23449Eae2BC890db1649AA3071b0e6A9Aa97433b
# Expected: 0x18d1391800000000000000000000000023449eae2bc890db1649aa3071b0e6a9aa97433b
```

Each payload appears exactly once and the target twice. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "nonce()(uint256)" -r $RPC   # 77
cast call 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D "owner()(address)" -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/110-unichain-sepolia-set-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D` (Unichain Sepolia SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000067`
  - **Before:** `0x0000000000000000000000004ab3387810ef500bfe05a49dc53a44c222cbab3e`
  - **After:**  `0x000000000000000000000000f10b9b33ae8da0581e08ab7ca9ece394301843a9`
  - **Summary:** `batcherHash`.
- **Key:** `0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08`
  - **Before:** `0x000000000000000000000000565b71025ab4de80aca33c62e51439af56301493`
  - **After:**  `0x00000000000000000000000023449eae2bc890db1649aa3071b0e6a9aa97433b`
  - **Summary:** `unsafeBlockSigner` (`keccak256("systemconfig.unsafeblocksigner")`, `UNSAFE_BLOCK_SIGNER_SLOT()`).

#### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `77` → **After:** `78`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D "batcherHash()(bytes32)" -r $RPC        # 0x000000000000000000000000f10b9b33ae8da0581e08ab7ca9ece394301843a9
cast call 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D "unsafeBlockSigner()(address)" -r $RPC   # 0x23449Eae2BC890db1649AA3071b0e6A9Aa97433b
cast call 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D "owner()(address)" -r $RPC               # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B (unchanged)
```
