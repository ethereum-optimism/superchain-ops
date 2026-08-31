# Validation

This document can be used to validate the inputs and result of the execution of the transaction
which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the
values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger. They assume the safe
> nonces pinned in [config.toml](./config.toml) (3-of-3 `10`, Chain Governor `19`, FUS `68`,
> SC `66` — FUS/SC account for tasks 067-068
> ([#1521](https://github.com/ethereum-optimism/superchain-ops/pull/1521)), which sign first;
> task 066 was cancelled).
> Re-verify the live nonces before signing and re-simulate to regenerate these hashes if any
> has drifted.
>
> ### Unichain Chain Governor Safe (`0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`)
>
> - Domain Hash: `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `0x28e77c5d683769217491d0641e997b31da6e7af654ec5cd90c6f4fd4771f6197`
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xb0c759361456b890fc3d235e576bf0b96cb0d149550d8a191b16bb9a2d06317a`
>
> ### Security Council Safe (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xf3b9e1f953f3d8f772afeb40409becabf104485505327e62eb59d34ec50ec5b3`


## Task Calldata

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000002f12d621a16e2d3285929c9996f478508951dfe40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a000000000000000000000000000000000000000000000000000000000000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a00000000000000000000000000000000000000000000000000000000
```

## Understanding Task Calldata

The two ownership transfers are batched into one `Multicall3.aggregate3Value` with selector
`0x174dea71` (the first four bytes of the task calldata above). Both inner payloads are the
same `transferOwnership(address)` call (selector `0xf2fde38b`) with the new owner
[`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/op.toml#L46)
as the only argument.

**Call 1 — `DisputeGameFactoryProxy.transferOwnership(newOwner)`**

- To: [`0x2F12d621a16e2d3285929C9996f478508951dFe4`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/unichain.toml#L52) (DisputeGameFactoryProxy)
- Inner calldata: `0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a`

**Call 2 — `ProxyAdmin.transferOwnership(newOwner)`** (performed last, per the template)

- To: [`0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/extra/addresses/addresses.json#L161) (ProxyAdmin)
- Inner calldata: `0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a`

To verify the inner calldata fingerprint:

```bash
cast calldata "transferOwnership(address)" 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
# Expected: 0xf2fde38b0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a
```

To decode the full calldata back into the two calls and confirm no additional content is
present:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

## Simulation

This task changes L1 state only; there is no L2 side.

```bash
cd src/tasks/eth/069-unichain-l1-ownership-transfers
just simulate-stack eth 069-unichain-l1-ownership-transfers chain-governor # or foundation|council
```

The output prints domain and message hashes (to check against the expected ones at the top of
this file) and a Tenderly simulation link. Open the link, paste the
[task calldata](#task-calldata) into the **Raw input data** field and simulate: the state diff
must match [Task State Changes](#task-state-changes) and the **Events** must show two
`OwnershipTransferred` events, one from each contract, both with `newOwner`
`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`.

## Task State Changes

### L1 State Changes

#### `0x24424336F04440b1c28685a38303aC33C9D14a25` (Security Council LivenessGuard) — council path only

- **Key:**          `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Before:** `0x00...00`
  - **After:**  the simulation block timestamp
  - **Summary:** `lastLive[0xca11bde05977b3631167028862bE2a173976CA11]` — a **simulation
    artifact**. The simulation overrides the child safe's owner set so Multicall3 can act as
    the sole signer, and the Security Council's LivenessGuard records a liveness timestamp for
    that simulated signer.

#### `0x6d5B183F538ABB8572F5cD17109c617b994D5833` (Unichain 3-of-3, root safe) — all paths

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...0a` (10)
  - **After:**  `0x...0b` (11)
  - **Summary:** nonce increment of the root safe executing the task.
- **Key (chain-governor path):** `0xf271bf34a10e3ead0b3c67913ad3dd203c54b4818a895836046a1d91e1ea67cb`
- **Key (foundation path):**     `0x41ce2f487a1356cf304e9915814f4c5f76738edce8fcba6190cd74d1c1c01ba1`
- **Key (council path):**        `0xc70e711154a08e5c7107f96c8c91e187e02893a179248cc779e4f1b807e7f839`
  - **Before:** `0x00...00`
  - **After:**  `0x00...01`
  - **Summary:** `approvedHashes[<child safe>][<root safe tx hash>] = 1` — the child safe's
    approval of the task.

#### `0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4` ([ProxyAdmin](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/extra/addresses/addresses.json#L161))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000006d5b183f538abb8572f5cd17109c617b994d5833`
  - **After:**  `0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **Summary:** Ownable owner slot — L1 ProxyAdmin ownership transferred to the OP-governed
    L1PAO. Pre-state: `cast storage 0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4 0x0 --rpc-url mainnet`

#### `0x2F12d621a16e2d3285929C9996f478508951dFe4` ([DisputeGameFactoryProxy](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/unichain.toml#L52))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000006d5b183f538abb8572f5cd17109c617b994d5833`
  - **After:**  `0x0000000000000000000000005a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
  - **Summary:** OwnableUpgradeable owner slot (`0x33`) — DisputeGameFactory ownership
    transferred to the OP-governed L1PAO. Pre-state:
    `cast storage 0x2F12d621a16e2d3285929C9996f478508951dFe4 0x33 --rpc-url mainnet`

#### `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC` (Unichain Chain Governor Safe)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...13` (19)
  - **After:**  `0x...14` (20)
  - **Summary:** nonce increment of the approving child safe.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Upgrade Safe)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...44` (68)
  - **After:**  `0x...45` (69)
  - **Summary:** nonce increment of the approving child safe.

#### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council Safe)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...42` (66)
  - **After:**  `0x...43` (67)
  - **Summary:** nonce increment of the approving child safe.

### L2 State Changes

None — this task changes L1 ownership only. The L2 `ProxyAdmin` is moved by
[070-unichain-l2pao-transfer](../070-unichain-l2pao-transfer/README.md).

## Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

# Changed by this task — both owners:
cast call 0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4 "owner()(address)" -r $RPC
cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "owner()(address)" -r $RPC
# → each: 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A

# Must be UNCHANGED — SystemConfig owner stays with the operator:
cast call 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6 "owner()(address)" -r $RPC
# → 0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1
```
