# Validation

This document can be used to validate the inputs and result of the execution of the transaction
which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the
values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger. They assume the safe
> nonce pinned in [config.toml](./config.toml) (Unichain Sepolia Safe `46` — one ahead of task
> 107's pin, since 107 executes first; the pin applies whether or not 107 has been signed yet).
> Re-verify the live nonce before signing and re-simulate to regenerate these hashes if it has
> drifted.
>
> ### Unichain Sepolia Safe (`0xd363339eE47775888Df411A163c586a8BdEA9dbf`)
>
> - Domain Hash: `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `0x3c5c0f94ad659edcbbf86a29d6633543f2a6bdf49c2a28f83d72f605aa545e62`

Safe transaction hash (`keccak256(0x1901 ‖ domain ‖ message)`, displayed by Safe tooling):
`0x517e68405e7b29a8a9a126e2cb909e21c4b70687effa2944ada2367a748a6448`

## Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000d83dab629f0e0f9d36c0cbc89b69a489f0751bd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000002fc3ffc903729a0f03966b917003800b145f67f30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Understanding Task Calldata

The payload is the `_data` argument of a single
`depositTransaction(0x4200000000000000000000000000000000000018, 0, 200000, false, _data)` call
to the Unichain Sepolia
[`OptimismPortal`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/unichain.toml#L51)
(`0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD`), wrapped in a `Multicall3.aggregate3Value` with
selector `0x174dea71` (the first four bytes of the task calldata above). On L2, the deposit
executes with the **aliased Unichain Sepolia Safe** (`0xe474339ee47775888df411A163c586a8bDEaaEd0`)
as sender — the current L2 `ProxyAdmin` owner, which `transferOwnership` authorizes against.

**Call 1 — `ProxyAdmin.transferOwnership(aliasedNewOwner)`**

- To (L2): `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)
- Inner calldata: `transferOwnership(address)` selector `0xf2fde38b`, arg
  `0x2FC3ffc903729a0f03966b917003800B145F67F3`

The argument is the L1-to-L2 alias of the
[OP-governed Sepolia L1PAO](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/op.toml#L47).
To verify the inner calldata fingerprint and the alias:

```bash
cast calldata "transferOwnership(address)" 0x2FC3ffc903729a0f03966b917003800B145F67F3
# Expected: 0xf2fde38b0000000000000000000000002fc3ffc903729a0f03966b917003800b145f67f3

# Unalias: subtract the alias offset to recover the L1 address
python3 -c "print(hex((0x2FC3ffc903729a0f03966b917003800B145F67F3 - 0x1111000000000000000000000000000000001111) % 2**160))"
# Expected: 0x1eb2ffc903729a0f03966b917003800b145f56e2
```

To decode the full calldata and confirm no additional content is present:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

## L1 and L2 Simulation

### L1 Simulation

```bash
cd src/tasks/sep/108-unichain-l2pao-transfer
just simulate-stack sep 108-unichain-l2pao-transfer
```

The output prints domain and message hashes (to check against the expected ones at the top of
this file) and a Tenderly simulation link. Open the link, paste the
[task calldata](#task-calldata) into the **Raw input data** field and simulate: the state diff
must match [L1 State Changes](#l1-state-changes) and the **Events** must show one
`TransactionDeposited` event emitted by the portal, with `from`
`0xe474339ee47775888df411A163c586a8bDEaaEd0` (the aliased Unichain Sepolia Safe), `to`
`0x4200000000000000000000000000000000000018`, and the `transferOwnership` payload above inside
`opaqueData`.

### L2 Simulation

The deposit executes on Unichain Sepolia only after the L1 transaction lands, so its effect is
verified by replaying the inner call on a Tenderly Virtual TestNet fork of Unichain Sepolia and
inspecting the **full state diff** (a full diff also exposes any write beyond the expected
one):

1. In [dashboard.tenderly.co](https://dashboard.tenderly.co), select your project → **Virtual
   TestNets** → **Create Virtual TestNet**: parent network **Unichain Sepolia** (chain ID
   1301), fork from latest block.
2. From the TestNet's overview, copy the **Admin RPC** URL and run the replay against it. The
   Admin RPC accepts transactions from any sender, so no key or impersonation is needed:

   ```bash
   L2RPC=<Admin RPC URL>
   ALIASED_OLD=0xe474339ee47775888df411A163c586a8bDEaaEd0
   ALIASED_NEW=0x2FC3ffc903729a0f03966b917003800B145F67F3

   # Fund the aliased Unichain Sepolia Safe (the deposit's L2 sender) with 1 ETH for gas:
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

#### `0xd363339eE47775888Df411A163c586a8BdEA9dbf` (Unichain Sepolia Safe, root safe)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...2e` (46, per the pinned override — task 107 advances the live nonce 45 → 46)
  - **After:**  `0x...2f` (47)
  - **Summary:** nonce increment of the safe executing the task. This is a single-safe task:
    the owners are EOAs, so there are no child-safe approval writes.

#### `0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD` ([OptimismPortal](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/unichain.toml#L51))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `ResourceMetering.ResourceParams` — packed as `prevBaseFee` (low 16 bytes),
    `prevBoughtGas` (next 8 bytes), `prevBlockNum` (high 8 bytes). Expected after-values:
    `prevBoughtGas` = `0x30d40` = **200,000**, the gas bought by the single deposit;
    `prevBlockNum` = the simulation block (block-dependent). Only this slot of the portal may
    change.

### L2 State Changes

#### `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x000000000000000000000000e474339ee47775888df411a163c586a8bdeaaed0`
  - **After:**  `0x0000000000000000000000002fc3ffc903729a0f03966b917003800b145f67f3`
  - **Summary:** Ownable owner slot — L2 ProxyAdmin owner rotated from the aliased Unichain
    Sepolia Safe to the aliased OP-governed Sepolia L1PAO, matching OP Sepolia's L2 ProxyAdmin
    owner. Pre-state: `cast storage 0x4200000000000000000000000000000000000018 0x0 --rpc-url https://sepolia.unichain.org`

## Post-execution verification calls

After the deposit is relayed on Unichain Sepolia:

```bash
RPC=https://sepolia.unichain.org

# Changed by this task:
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" -r $RPC
# → 0x2FC3ffc903729a0f03966b917003800B145F67F3
```

If the value did not update, the deposit reverted on L2 while the L1 tx still shows success:
inspect the relayed L2 transaction sent from the aliased Unichain Sepolia Safe
(`0xe474339ee47775888df411A163c586a8bDEaaEd0`) to the L2 ProxyAdmin predeploy on a Unichain
Sepolia explorer and confirm the `OwnershipTransferred` event.
