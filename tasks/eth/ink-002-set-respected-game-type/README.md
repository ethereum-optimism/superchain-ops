# Deputy Guardian - Enable Permissioness Dispute Game for Ink Mainnet

Status: DRAFT, NOT READY TO SIGN

## Objective

This task updates the `respectedGameType` in the `OptimismPortalProxy` to `CANNON`, enabling users to permissionlessly propose outputs as well as for anyone to participate in the dispute of these proposals. This action requires all in-progress withdrawals to be re-proven against a new `FaultDisputeGame` that was created after this update occurs.

The batch will be executed on chain ID `1`, and contains `1` transaction.

## Tx #1: Update `respectedGameType` in the `OptimismPortalProxy`

Updates the `respectedGameType` to `CANNON` in the `OptimismPortalProxy`, enabling permissionless proposals and challenging.

**Function Signature:** `setRespectedGameType(address,uint32)`

**To:** `0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B`

**Value:** `0 WEI`

**Raw Input Data**

|Function Selector Signature| OptimismPortalProxyAddress (left-padded to 32 bytes) | `CANNON` game type, hardcoded to 0 and left-padded |
|--------------------------|--------------------------------------------|--------------------------------------------|
|0xa1155ed9|0000000000000000000000005d66C1782664115999C47c9fA5cd031f495D3e4F|0000000000000000000000000000000000000000000000000000000000000000|

### Inputs

**\_portal:** `<user-input>`

**\_gameType:** `0` (`CANNON`)

## Preparing the Operation

1. Locate the address of the `OptimismPortalProxy` to change the respected game type of. For OP Stack chains that support fault proofs, the contract address can be located in the respective `.toml` file in the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry/tree/2c96a89df841013a59269fa7adc12c77b870310e/superchain/configs/mainnet).

2. Generate the batch with `just generate-input <OptimismPortalProxyAddress>`.

3. Set the `L2_CHAIN_NAME` configuration to the appropriate chain in the `.env` file. Applicable chain names can be found in the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry/tree/2c96a89df841013a59269fa7adc12c77b870310e/superchain/configs/mainnet).

4. Collect signatures and execute the action according to the instructions in [SINGLE.md](../../../../SINGLE.md).

### State Validations

The two state modifications that are made by this action are:

1. An update to the nonce (increment of `1`) of the `DeputyGuardianModule` safe.
2. An update to the shared slot between the `respectedGameType` and `respectedGameTypeUpdatedAt` variables.

The state changes should look something like this:

![state-diff](./images/state_diff.png)

Slot [`0x000000000000000000000000000000000000000000000000000000000000003b`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L100-L113) in the `OptimismPortalProxy` has the following packed layout:

| Offset     | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| `[0, 20)`  | Unused; Should be zero'd out.                                |
| `[20, 28)` | `respectedGameTypeUpdatedAt` timestamp (64 bits, big-endian) |
| `[28, 32)` | `respectedGameType` (32 bits, big-endian)                    |

Note that the offsets in the above table refer to the slot value's big-endian representation. You can compute the offset values with chisel:
```
➜ uint256 x = 0x000000000000000000000000000000000000000000000000669faf8900000000
➜ uint64 respectedGameTypeUpdatedAt = uint64(x >> 32)
➜ respectedGameTypeUpdatedAt
Type: uint64
├ Hex: 0x
├ Hex (full word): 0x669faf89
└ Decimal: 1721741193
➜ uint32 respectedGameType = uint32(x & 0xFFFFFFFF)
➜ respectedGameType
Type: uint32
├ Hex: 0x
├ Hex (full word): 0x0
└ Decimal: 0
```

To verify the diff:

1. Check that the only modification to state belongs to the `OptimismPortalProxy` at slot [`0x000000000000000000000000000000000000000000000000000000000000003b`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L100-L113).
2. Check that the lower 4 bytes equal `0` (`CANNON`) when read as a big-endian 32-bit uint.
3. Check that bytes `[20, 28]` equal the timestamp of the transaction's submission when read as a big-endian 64-bit uint.
