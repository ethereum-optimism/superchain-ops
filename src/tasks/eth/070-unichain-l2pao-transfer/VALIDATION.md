# Validation

This document can be used to validate the inputs and result of the execution of the transaction
which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the
values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger. They assume the safe
> nonces pinned in [config.toml](./config.toml) (3-of-3 `11`, Chain Governor `20`, FUS `69`,
> SC `67` — each one ahead of task 069's pins, since 069 executes first; the pins apply whether
> or not 069 has been signed yet). Re-verify the live nonces before signing and re-simulate to
> regenerate these hashes if any has drifted.
>
> ### Unichain Chain Governor Safe (`0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`)
>
> - Domain Hash: `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `0xe2d1b1a28173296b9bbd2fe2058fa55bf3202bfa7a74de07573b677a32e6e6ed`
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x2406b6c854f59e1a91b14d0f017b5cf9a5957ba38b85433b3dcc22a2274d768d`
>
> ### Security Council Safe (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x3b23b958ffc28a4c122967f5c12d0cd433b80f50d24a3abad6f1c8fa602a22a9`


## Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Understanding Task Calldata

The payload is the `_data` argument of a single
`depositTransaction(0x4200000000000000000000000000000000000018, 0, 200000, false, _data)` call
to the Unichain Mainnet
[`OptimismPortal`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/unichain.toml#L50)
(`0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2`), wrapped in a `Multicall3.aggregate3Value` with
selector `0x174dea71` (the first four bytes of the task calldata above). On L2, the deposit
executes with the **aliased Unichain 3-of-3** (`0x7E6c183F538abb8572F5cd17109C617b994d6944`)
as sender — the current L2 `ProxyAdmin` owner, which `transferOwnership` authorizes against.

**Call 1 — `ProxyAdmin.transferOwnership(aliasedNewOwner)`**

- To (L2): `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)
- Inner calldata: `transferOwnership(address)` selector `0xf2fde38b`, arg
  `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`

The argument is the L1-to-L2 alias of the
[OP-governed L1PAO](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/op.toml#L46).
To verify the inner calldata fingerprint and the alias:

```bash
cast calldata "transferOwnership(address)" 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
# Expected: 0xf2fde38b0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b

# Unalias: subtract the alias offset to recover the L1 address
python3 -c "print(hex((0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b - 0x1111000000000000000000000000000000001111) % 2**160))"
# Expected: 0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a
```

To decode the full calldata and confirm no additional content is present:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

## L1 and L2 Simulation

### L1 Simulation

```bash
cd src/tasks/eth/070-unichain-l2pao-transfer
just simulate-stack eth 070-unichain-l2pao-transfer chain-governor # or foundation|council
```

The output prints domain and message hashes (to check against the expected ones at the top of
this file) and a Tenderly simulation link. Open the link, paste the
[task calldata](#task-calldata) into the **Raw input data** field and simulate: the state diff
must match [L1 State Changes](#l1-state-changes) and the **Events** must show one
`TransactionDeposited` event emitted by the portal, with `from`
`0x7E6c183F538abb8572F5cd17109C617b994d6944` (the aliased 3-of-3), `to`
`0x4200000000000000000000000000000000000018`, and the `transferOwnership` payload above inside
`opaqueData`.

### L2 Simulation

The deposit executes on Unichain only after the L1 transaction lands, so its effect is
verified by replaying the inner call on a Tenderly Virtual TestNet fork of Unichain and
inspecting the **full state diff** (a full diff also exposes any write beyond the expected
one):

1. In [dashboard.tenderly.co](https://dashboard.tenderly.co), select your project → **Virtual
   TestNets** → **Create Virtual TestNet**: parent network **Unichain** (chain ID 130), fork
   from latest block.
2. From the TestNet's overview, copy the **Admin RPC** URL and run the replay against it. The
   Admin RPC accepts transactions from any sender, so no key or impersonation is needed:

   ```bash
   L2RPC=<Admin RPC URL>
   ALIASED_OLD=0x7E6c183F538abb8572F5cd17109C617b994d6944
   ALIASED_NEW=0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b

   # Fund the aliased 3-of-3 (the deposit's L2 sender) with 1 ETH for gas:
   cast rpc tenderly_setBalance $ALIASED_OLD 0xDE0B6B3A7640000 --rpc-url $L2RPC

   # The inner call (cross-check the calldata bytes above):
   cast send 0x4200000000000000000000000000000000000018 "transferOwnership(address)" $ALIASED_NEW \
     --from $ALIASED_OLD --unlocked --rpc-url $L2RPC --gas-limit 200000
   ```

3. Back in the dashboard, open the transaction and check its **State Changes** tab against
   [L2 State Changes](#l2-state-changes): the expected slot with the expected before/after
   values, and nothing else.

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
  - **Before:** `0x...0b` (11, per the pinned override — task 069 advances the live nonce 10 → 11)
  - **After:**  `0x...0c` (12)
  - **Summary:** nonce increment of the root safe executing the task.
- **Key (chain-governor path):** `0x8ee9f8b21a9ddf4bd3a285179d476747ed35817ad444da282e9e00c6e67bd7eb`
- **Key (foundation path):**     `0x1f0624dc949b7f0ef8f36c728a49c5b4fe2273d882d083c5f3a2fe50bcfa13f9`
- **Key (council path):**        `0xfa72e59f819249d3c7bd5c1a043b08ad6999f0101d20f441cf56fbda7692a4e2`
  - **Before:** `0x00...00`
  - **After:**  `0x00...01`
  - **Summary:** `approvedHashes[<child safe>][<root safe tx hash>] = 1` — the child safe's
    approval of the task.

#### `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` ([OptimismPortal](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/unichain.toml#L50))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `ResourceMetering.ResourceParams` — packed as `prevBaseFee` (low 16 bytes),
    `prevBoughtGas` (next 8 bytes), `prevBlockNum` (high 8 bytes). Expected after-values:
    `prevBoughtGas` = `0x30d40` = **200,000**, the gas bought by the single deposit;
    `prevBlockNum` = the simulation block (block-dependent). Only this slot of the portal may
    change.

#### `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC` (Unichain Chain Governor Safe)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...14` (20)
  - **After:**  `0x...15` (21)
  - **Summary:** nonce increment of the approving child safe.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Upgrade Safe)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...45` (69)
  - **After:**  `0x...46` (70)
  - **Summary:** nonce increment of the approving child safe.

#### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council Safe)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...43` (67)
  - **After:**  `0x...44` (68)
  - **Summary:** nonce increment of the approving child safe.

### L2 State Changes

#### `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000007e6c183f538abb8572f5cd17109c617b994d6944`
  - **After:**  `0x0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b`
  - **Summary:** Ownable owner slot — L2 ProxyAdmin owner rotated from the aliased Unichain
    3-of-3 to the aliased OP-governed L1PAO, matching OP Mainnet's L2 ProxyAdmin owner.
    Pre-state: `cast storage 0x4200000000000000000000000000000000000018 0x0 --rpc-url https://mainnet.unichain.org`

## Post-execution verification calls

After the deposit is relayed on Unichain Mainnet:

```bash
RPC=https://mainnet.unichain.org

# Changed by this task:
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" -r $RPC
# → 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
```

If the value did not update, the deposit reverted on L2 while the L1 tx still shows success:
inspect the relayed L2 transaction sent from the aliased 3-of-3
(`0x7E6c183F538abb8572F5cd17109C617b994d6944`) to the L2 ProxyAdmin predeploy on a Unichain
explorer and confirm the `OwnershipTransferred` event.
