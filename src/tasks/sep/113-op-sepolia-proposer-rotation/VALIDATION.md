# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonces in [config.toml](./config.toml) (L1PAO 58,
FoundationUpgradeSafe 80, SecurityCouncil 72) and move
only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0xb13930f36953ea2fcb332ca042dedc21706fa42d806839fe3727255d4d6fc788`
>
> ### SecurityCouncil (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x023f6f8060d5d007a312d56cfa2e9c11fed4785d22a199b027760a32c8431538`

Root L1PAO (`0x1Eb2fFc903729a0F03966B917003800b145F56E2`) safe transaction hash (identical on both signing paths):
`0xec1227c711f2cbac99c6114dc5e30aefadce790ac2440def4c50492479c1d48a`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/113-op-sepolia-proposer-rotation
just simulate-stack sep 113-op-sepolia-proposer-rotation council   # or foundation
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, the outer
   `execTransaction` that the child safe sends to the L1PAO, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   storage writes must match [Task State Changes](#task-state-changes), which also explains the
   simulation's nonce overrides and sender nonce bump.
3. The call trace shows one `setImplementation` on `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1` with `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` and the 40-byte `_args` in the [Understanding Task Calldata](#understanding-task-calldata) table, and no other call.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the L1PAO
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000005f9613adb30026ffd634f38e5c4dfd30a197fa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c4b107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d69100000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000028a1cec548926eb5d69aa3b7b57d371edbdd03e64b9884c33c65111da7bbed0e63cd2392f503b135f500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the L1PAO (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1` (DisputeGameFactoryProxy) | `setImplementation(uint32,address,bytes)` | `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, `_args = 0xa1cec548926eb5d69aa3b7b57d371edbdd03e64b9884c33c65111da7bbed0e63cd2392f503b135f5` (anchorStateRegistry \| proposer) |

To verify the payload fingerprints:

```bash
cast calldata "setImplementation(uint32,address,bytes)" 5 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 0xa1cec548926eb5d69aa3b7b57d371edbdd03e64b9884c33c65111da7bbed0e63cd2392f503b135f5
# Expected: 0xb107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d69100000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000028a1cec548926eb5d69aa3b7b57d371edbdd03e64b9884c33c65111da7bbed0e63cd2392f503b135f5000000000000000000000000000000000000000000000000
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x1Eb2fFc903729a0F03966B917003800b145F56E2 "nonce()(uint256)" -r $RPC   # 58
cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "nonce()(uint256)" -r $RPC   # 80
cast call 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 "nonce()(uint256)" -r $RPC   # 72
cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691
cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0xa1cec548926eb5d69aa3b7b57d371edbdd03e64b49277ee36a024120ee218127354c4a3591dc90a9
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/113-op-sepolia-proposer-rotation

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

### Task State Changes

#### `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1` (OP Sepolia DisputeGameFactoryProxy)

- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf7`
  - **Before:** `0xa1cec548926eb5d69aa3b7b57d371edbdd03e64b49277ee36a024120ee218127`
  - **After:**  `0xa1cec548926eb5d69aa3b7b57d371edbdd03e64b9884c33c65111da7bbed0e63`
- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf8`
  - **Before:** `0x354c4a3591dc90a9000000000000000000000000000000000000000000000000`
  - **After:**  `0xcd2392f503b135f5000000000000000000000000000000000000000000000000`
  - **Summary:** the two data slots of the `gameArgs[5]` bytes value: the first 20 bytes (anchorStateRegistry) are unchanged, the proposer moves to `0x9884C33C65111DA7Bbed0e63cD2392F503b135F5`. `gameImpls[5]` is rewritten with its current value (no diff); `initBonds[5]` is not written (no `bond` in the config, live value 0).

#### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO, root safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `58` → **After:** `59`
  - **Summary:** nonce increment of the root safe. The before-value reflects the nonce state
    override in [config.toml](./config.toml).
- **Key (foundation path):** `0xc22d672bd552048ff3a9cfef266edc817ac3967b7e5b2c926ab158f01240b99e`
- **Key (council path):** `0x729778a22e65b113d96d71bbf2109fce52737d01296614bad458992348bc1f68`
  - **Before:** `0` → **After:** `1`
  - **Summary:** `approvedHashes[<child safe>][0xec1227c7…]`, the child safe's approval. Only the
    key of the path being simulated is written. Derive with
    `cast index bytes32 0xec1227c711f2cbac99c6114dc5e30aefadce790ac2440def4c50492479c1d48a $(cast index address <child> 8)`.

#### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe), foundation path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `80` → **After:** `81`
  - **Summary:** nonce increment of the approving child safe.

#### `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (SecurityCouncil), council path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `72` → **After:** `73`
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

cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0xa1cec548926eb5d69aa3b7b57d371edbdd03e64b9884c33c65111da7bbed0e63cd2392f503b135f5
cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 (unchanged)
cast call 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1 "initBonds(uint32)(uint256)" 5 -r $RPC   # 0 (unchanged)
```
