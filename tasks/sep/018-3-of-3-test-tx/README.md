# Sepolia 3-of-3 Multisig Test Transaction

Status: [DRAFT]()

## Objective


## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/018-3-of-3-test-tx/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This is a simple transaction that sets storage on a storage setter contract. The purpose is to prove we have access to the new 3-of-3 safe that was created at address: `0xaAa1202FA447F257b7Cec1fd1CD0Da154481AC73`.