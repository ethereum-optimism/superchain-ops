# Sepolia Update Signers of the `FakeFuS`

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x49e06b2aec3f5fe428fd8d3affde24dd4a0230feb56676fe509ba4e908fd8b37)

## Objective

This task **update** the signers of the `FakeFuS`(`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`) on Sepolia.
Since some signers are not active anymore or part of the organisation, this is necessary to remove them.
The **2 signers** that will be removed by this task will be:

- `0xad70Ad7Ac30Cee75EB9638D377EACD8DfDfE0C3c`
- `0xE09d881A1A13C805ED2c6823f0C7E4443A260f2f`

Moreover, 3 engineers will be added (_Engineer 1_: `0x41fb1d8c3262e88a056ee3099f5718405CC8cAdE`, _Engineer 2_: `0x95E774787A63f145f7B05028a1479bDc9D055f3d` and _Engineer 3_: `0xa03dafade71f1544f4b0120145eec9b89105951f`) that require to sign on Sepolia will be added as owners on both Safes.

This action will be performed by swaping previous owner that was not active anymore by the new _Engineer 1_ and _Engineer 2_.

To Recap the action for swaping will be:
| PreviousOwner | newOwner |
| --- | --- |
| 0xad70Ad7Ac30Cee75EB9638D377EACD8DfDfE0C3c | 0x95E774787A63f145f7B05028a1479bDc9D055f3d |
| 0xE09d881A1A13C805ED2c6823f0C7E4443A260f2f| 0x41fb1d8c3262e88a056ee3099f5718405CC8cAdE |

For _Engineer 3_ we will be using the `addOwnerWithThreshold(address owner, uint256 _threshold)` function of the safe without changing the threshold.

To Recap the action will be:
| Owner | Threshold |
| --- | --- |
| 0xa03dafade71f1544f4b0120145eec9b89105951f| 2 |

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/023-refresh-signers-FakeFuS/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
