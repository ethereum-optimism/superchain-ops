# 075-deputy-pause-key-rotation

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x3a41370d762b275dc0b30f6c7f957d4d959d4bddea36fb14c13d76dcc0320704)

## Objective

Rotates the `DeputyPauseModule` Deputy EOA from `0x6A07d585eddBa8F9A4E17587F4Ea5378De1c3bAc` to `0x8D2AAe4009418Ef6D83F1F2c90D4dAc3cE2b5D4f`.
To achieve this, we will use the `setDeputy` function of the `DeputyPauseModule` contract deployed at `0xC10dAc07d477215A1ebeBaE1dd0221c1F5d241D2`.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/src/template/DeputyPauseKeyRotationTemplate.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

Rotates the `DeputyPauseModule` Deputy EOA from `0x6A07d585eddBa8F9A4E17587F4Ea5378De1c3bAc` to `0x8D2AAe4009418Ef6D83F1F2c90D4dAc3cE2b5D4f` in the [DeputyPauseModule](https://sepolia.etherscan.io/address/0xC10dAc07d477215A1ebeBaE1dd0221c1F5d241D2#code).

## Signing and execution

This task has to be signed by the [FoundationUpgradeSafe](https://sepolia.etherscan.io/address/0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B).
