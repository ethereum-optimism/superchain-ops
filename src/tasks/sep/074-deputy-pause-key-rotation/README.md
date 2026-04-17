# 074-deputy-pause-key-rotation

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xb5f1725e6f29081ca47e25d97e4f572e4e82dfde9678a4b9d5e45139876af8c7)

## Objective

Rotates the `DeputyPauseModule` Deputy EOA from `0x6A07d585eddBa8F9A4E17587F4Ea5378De1c3bAc` to `0x8D2AAe4009418Ef6D83F1F2c90D4dAc3cE2b5D4f`.
To achieve this, we will use the `setDeputy` function of the `DeputyPauseModule` contract deployed at `0xc6f7C07047ba37116A3FdC444Afb5018f6Df5758`.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/src/template/DeputyPauseKeyRotationTemplate.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

Rotates the `DeputyPauseModule` Deputy EOA from `0x6A07d585eddBa8F9A4E17587F4Ea5378De1c3bAc` to `0x8D2AAe4009418Ef6D83F1F2c90D4dAc3cE2b5D4f` in the [DeputyPauseModule](https://sepolia.etherscan.io/address/0xc6f7C07047ba37116A3FdC444Afb5018f6Df5758#code).

## Signing and execution

This task has to be signed by the [FakeFoundationOperationsSafe](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E).
