# 009-deputy-pause-key-rotation Deputy Pause Module Rotation key

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x15eea8c7a5b7a2d6ec5f9434265db54504aec463dbb39b2cc341d15e15fb508f)

## Objective

Rotates the `DeputyPauseModule` Deputy EOA from `0xfcb2575ab431a175669ae5007364193b2d298dfe` to `0x6A07d585eddBa8F9A4E17587F4Ea5378De1c3bAc`.
To achieve this, we will need to use the `setDeputy` function of the `DeputyPauseModule` contract deployed at `0xc6f7C07047ba37116A3FdC444Afb5018f6Df5758`.

![CleanShot 2025-04-10 at 10 15 35@2x](https://github.com/user-attachments/assets/042bbb15-a19b-4edf-bff1-e79adaf4e2ce)

### Execution Timing

Expected to be executed the **10 APRIL 2025**.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/src/improvements/template/DeputyPauseRotationKey.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

Rotates the `DeputyPauseModule` Deputy EOA from `0xfcb2575ab431a175669ae5007364193b2d298dfe` to `0x6A07d585eddBa8F9A4E17587F4Ea5378De1c3bAc` into the [DeputyPauseModule](https://sepolia.etherscan.io/address/0x62f3972c56733aB078F0764d2414DfCaa99d574c#code).

## Signing and execution

This task has to be signed by the [FakeFoundationOperationsSafe](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)
