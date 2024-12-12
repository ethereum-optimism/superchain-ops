# Sepolia Update Signers `FakeSC`

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x343762f9c1cae4c0833f52b3cc12db3194e48066548efe69d2ec8a2925aec996)

## Objective

This task **update** the signers of the `FakeSC`(`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`) on Sepolia.
Since some signers are not active anymore or part of the organisation, this is necessary to remove them.
The **3 signers** that will be removed by this task will be:

- `0xE09d881A1A13C805ED2c6823f0C7E4443A260f2f`
- `0xad70Ad7Ac30Cee75EB9638D377EACD8DfDfE0C3c`
- `0x78339d822c23d943e4a2d4c3dd5408f66e6d662d`

Moreover, 3 engineers will be added (_Engineer 1_: `0x41fb1d8c3262e88a056ee3099f5718405CC8cAdE`, _Engineer 2_: `0x95E774787A63f145f7B05028a1479bDc9D055f3d` and _Engineer 3_: `0xa03dafade71f1544f4b0120145eec9b89105951f`) that require to sign on Sepolia will be added as owners on both Safes.

This action will be performed by swaping previous owner that was not active anymore by the new _Engineer 1_ and _Engineer 2_ and _Engineer 3_ using the `swapOwner(address prevOwner, address oldOwner, address newOwner)` function of the safes.

To Recap the action will be:
| PreviousOwner | newOwner |
| --- | --- |
| 0xad70Ad7Ac30Cee75EB9638D377EACD8DfDfE0C3c | 0x95E774787A63f145f7B05028a1479bDc9D055f3d |
| 0xE09d881A1A13C805ED2c6823f0C7E4443A260f2f | 0x41fb1d8c3262e88a056ee3099f5718405CC8cAdE |
| 0x78339d822c23d943e4a2d4c3dd5408f66e6d662d | 0xa03dafade71f1544f4b0120145eec9b89105951f |

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/024-refresh-signers-fakeSC/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
