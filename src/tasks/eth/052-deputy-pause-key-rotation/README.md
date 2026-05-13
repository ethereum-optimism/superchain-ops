# 052-deputy-pause-key-rotation

Status: [EXECUTED](https://etherscan.io/tx/0x9be0d40037f1a556aafcf1b6fd700005d49552826e27b494c8ddc549685b8b8b)

## Objective

Rotates the `DeputyPauseModule` Deputy EOA from `0x352f1defb49718e7ea411687e850aa8d6299f7ac` to `0x2fA150379bF32b6d79Eeb4ff9bD280E76049a87c`.
To achieve this, we will use the `setDeputy` function of the `DeputyPauseModule` contract deployed at `0x76fC2F971FB355D0453cF9F64d3F9E4f640E1754`.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/src/template/DeputyPauseKeyRotationTemplate.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

Rotates the `DeputyPauseModule` Deputy EOA from `0x352f1defb49718e7ea411687e850aa8d6299f7ac` to `0x2fA150379bF32b6d79Eeb4ff9bD280E76049a87c` in the [DeputyPauseModule](https://etherscan.io/address/0x76fC2F971FB355D0453cF9F64d3F9E4f640E1754#code).

## Signing and execution

This task has to be signed by the [FoundationUpgradeSafe](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92).
