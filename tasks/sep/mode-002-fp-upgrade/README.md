# Mode Sepolia Permissioned Fault Proofs

Status: [[EXECUTED](https://sepolia.etherscan.io/tx/0x6aa6d9b5ae6920a3d017ff282e54bc59892635c56cab25b3f9094c97dd060486)]

## Objective

The objective of this task is to upgrade Mode Sepolia to Permissioned Fault Proofs at contracts
version `op-contracts/v1.8.0`.

## Simulation

Please see "Simulating and Verifying the Transaction" in [NESTED.md](../../../NESTED.md).

When simulating, ensure the logs say:

```sh
Using script /your/path/to/superchain-ops/tasks/sep/mode-002-fp-upgrade/NestedSignFromJson.s.sol
```

This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks **WILL NOT RUN**.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction"
section of [NESTED.md](../../../NESTED.md).

When executing, ensure the logs say:

```sh
Using script Using script /your/path/to/superchain-ops/tasks/sep/mode-002-fp-upgrade/NestedSignFromJson.s.sol
```

This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks **WILL NOT RUN**.
