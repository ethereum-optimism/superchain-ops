# Deputy Guardian - Fall back to `PermissionedDisputeGame`

Status: CONTINGENCY TASK, SIGN AS NEEDED

## Objective

This batch udates the `respectedGameType` to `PERMISSIONED_CANNON` in the `OptimismPortalProxy`. This action requires all in-progress withdrawals to be re-proven against a new `PermissionedDisputeGame` that was created after this update occurs.

The batch will be executed on chain ID `11155111`, and contains `1` transactions.

## Tx #1: Update `respectedGameType` in the `OptimismPortalProxy`

Updates the `respectedGameType` to `PERMISSIONED_CANNON` in the `OptimismPortalProxy`, enabling permissioned proposals and challenging.

**Function Signature:** `setRespectedGameType(address,uint32)`

**To:** `0x4220C5deD9dC2C8a8366e684B098094790C72d3c`

**Value:** `0 WEI`

**Raw Input Data:** `0xa1155ed9000000000000000000000000<OptimismPortalProxyAddress------------>0000000000000000000000000000000000000000000000000000000000000001`

### Inputs

**\_gameType:** `1` (`PERMISSIONED_CANNON`)

**\_portal:** `<user-input>`

## Preparing the Operation

1. Locate the address of the `OptimismPortalProxy` to change the respected game type of.

2. Generate the batch with `just generate-input <OptimismPortalProxyAddress>`.

3. Set the `L2_CHAIN_NAME` configuration to the appropriate chain in the `.env` file.

4. Collect signatures and execute the action according to the instructions in [SINGLE.md](../../../../SINGLE.md).

### State Validations

The two state modifications that are made by this action are:

1. An update to the nonce of the Gnosis safe owner of the `DeputyGuardianModule`.
2. An update to the shared slot between the `respectedGameType` and `respectedGameTypeUpdatedAt` variables.

The state changes should look something like this:

![state-diff](./images/state_diff.png)

Slot [`0x000000000000000000000000000000000000000000000000000000000000003b`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L100C3-L113C5) in the `OptimismPortalProxy` has the following packed layout:

| Offset     | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| `[0, 20)`  | Unused; Should be zero'd out.                                |
| `[20, 28)` | `respectedGameTypeUpdatedAt` timestamp (64 bits, big-endian) |
| `[28, 32)` | `respectedGameType` (32 bits, big-endian)                    |

Note that the offsets in the above table refer to the slot value's big-endian representation. You can compute the offset values with chisel:
```
➜ uint256 x = 0x000000000000000000000000000000000000000000000000669eeed200000001
➜ uint64 respectedGameTypeUpdatedAt = uint64(x >> 32)
➜ respectedGameTypeUpdatedAt
Type: uint64
├ Hex: 0x
├ Hex (full word): 0x669eeed2
└ Decimal: 1721691858
➜ uint32 respectedGameType = uint32(x & 0xFFFFFFFF)
➜ respectedGameType
Type: uint32
├ Hex: 0x
├ Hex (full word): 0x1
└ Decimal: 1
```

To verify the diff:

1. Check that the only modification to state belongs to the `OptimismPortalProxy` at slot `0x000000000000000000000000000000000000000000000000000000000000003b`
1. Check that the lower 4 bytes equal `1` (`PERMISSIONED_CANNON`) when read as a big-endian 32-bit uint.
1. Check that bytes `[20, 28]` equal the timestamp of the transaction's submission when read as a big-endian 64-bit uint.
