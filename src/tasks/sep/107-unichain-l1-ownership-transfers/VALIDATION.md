# Validation

This document can be used to validate the inputs and result of the execution of the transaction
which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the
values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger. They assume the safe
> nonce pinned in [config.toml](./config.toml) (Unichain Sepolia Safe `45`, live as of
> 2026-08-31; the pending sep/105-106 tasks do not touch this safe). Re-verify the live nonce
> before signing and re-simulate to regenerate these hashes if it has drifted.
>
> ### Unichain Sepolia Safe (`0xd363339eE47775888Df411A163c586a8BdEA9dbf`)
>
> - Domain Hash: `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `0x6900ea187bf261d57d1371f285128be4673befbe64daef8cc809ae100633bfea`


## Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000120000000000000000000000000eff73e5aa3b9aec32c659aa3e00444d20a84394b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2000000000000000000000000000000000000000000000000000000000000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e200000000000000000000000000000000000000000000000000000000
```

## Understanding Task Calldata

The two ownership transfers are batched into one `Multicall3.aggregate3Value` with selector
`0x174dea71` (the first four bytes of the task calldata above). Both inner payloads are the
same `transferOwnership(address)` call (selector `0xf2fde38b`) with the new owner
[`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/op.toml#L47)
as the only argument.

**Call 1 — `DisputeGameFactoryProxy.transferOwnership(newOwner)`**

- To: [`0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/unichain.toml#L53) (DisputeGameFactoryProxy)
- Inner calldata: `0xf2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2`

**Call 2 — `ProxyAdmin.transferOwnership(newOwner)`** (performed last, per the template)

- To: [`0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/extra/addresses/addresses.json#L187) (ProxyAdmin)
- Inner calldata: `0xf2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2`

To verify the inner calldata fingerprint:

```bash
cast calldata "transferOwnership(address)" 0x1Eb2fFc903729a0F03966B917003800b145F56E2
# Expected: 0xf2fde38b0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2
```

To decode the full calldata back into the two calls and confirm no additional content is
present:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

## Simulation

This task changes L1 state only; there is no L2 side.

```bash
cd src/tasks/sep/107-unichain-l1-ownership-transfers
just simulate-stack sep 107-unichain-l1-ownership-transfers
```

The output prints domain and message hashes (to check against the expected ones at the top of
this file) and a Tenderly simulation link. Open the link, paste the
[task calldata](#task-calldata) into the **Raw input data** field and simulate: the state diff
must match [Task State Changes](#task-state-changes) and the **Events** must show two
`OwnershipTransferred` events, one from each contract, both with `newOwner`
`0x1Eb2fFc903729a0F03966B917003800b145F56E2`.

## Task State Changes

### L1 State Changes

#### `0xd363339eE47775888Df411A163c586a8BdEA9dbf` (Unichain Sepolia Safe, root safe)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...2d` (45)
  - **After:**  `0x...2e` (46)
  - **Summary:** nonce increment of the safe executing the task. This is a single-safe task:
    the owners are EOAs, so there are no child-safe approval writes.

#### `0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4` ([ProxyAdmin](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/extra/addresses/addresses.json#L187))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x000000000000000000000000d363339ee47775888df411a163c586a8bdea9dbf`
  - **After:**  `0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2`
  - **Summary:** Ownable owner slot — L1 ProxyAdmin ownership transferred to the OP-governed
    Sepolia L1PAO. Pre-state: `cast storage 0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4 0x0 --rpc-url sepolia`

#### `0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b` ([DisputeGameFactoryProxy](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/unichain.toml#L53))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x000000000000000000000000d363339ee47775888df411a163c586a8bdea9dbf`
  - **After:**  `0x0000000000000000000000001eb2ffc903729a0f03966b917003800b145f56e2`
  - **Summary:** OwnableUpgradeable owner slot (`0x33`) — DisputeGameFactory ownership
    transferred to the OP-governed Sepolia L1PAO. Pre-state:
    `cast storage 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b 0x33 --rpc-url sepolia`

### L2 State Changes

None — this task changes L1 ownership only. The L2 `ProxyAdmin` is moved by
[108-unichain-l2pao-transfer](../108-unichain-l2pao-transfer/README.md).

## Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

# Changed by this task — both owners:
cast call 0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4 "owner()(address)" -r $RPC
cast call 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b "owner()(address)" -r $RPC
# → each: 0x1Eb2fFc903729a0F03966B917003800b145F56E2

# Must be UNCHANGED — SystemConfig owner stays with the operator:
cast call 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D "owner()(address)" -r $RPC
# → 0x325B777f8F0bC71fb6b617Bc41A8703CA7077891
```
