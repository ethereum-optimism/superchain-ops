# 052-deputy-pause-key-rotation

Status: READY TO SIGN

## Objective

Rotates the `DeputyPauseModule` Deputy EOA from `0x352f1defb49718e7ea411687e850aa8d6299f7ac` to `0x2fA150379bF32b6d79Eeb4ff9bD280E76049a87c`.
To achieve this, we will use the `setDeputy` function of the `DeputyPauseModule` contract deployed at `0x126a736B18E0a64fBA19D421647A530E327E112C`.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/src/template/DeputyPauseKeyRotationTemplate.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

Rotates the `DeputyPauseModule` Deputy EOA from `0x352f1defb49718e7ea411687e850aa8d6299f7ac` to `0x2fA150379bF32b6d79Eeb4ff9bD280E76049a87c` in the [DeputyPauseModule](https://etherscan.io/address/0x126a736B18E0a64fBA19D421647A530E327E112C#code).

## Signing and execution

This task has to be signed by the [FoundationOperationsSafe](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A).
