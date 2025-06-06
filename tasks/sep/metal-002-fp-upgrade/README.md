# Metal Sepolia Permissioned Fault Proofs

Status: [[EXECUTED](https://sepolia.etherscan.io/tx/0xa360b8dc9abcf8bfa4aa3ffdb95de34f0481c57c88fa4778951cdd9286e5ef68)]

## Objective

The objective of this task is to upgrade Metal Sepolia to Permissioned Fault Proofs at contracts
version `op-contracts/v1.8.0`.

## Simulation

Please see "Simulating and Verifying the Transaction" in [NESTED.md](../../../NESTED.md).

When simulating, ensure the logs say:

```sh
Using script /your/path/to/superchain-ops/tasks/sep/metal-002-fp-upgrade/NestedSignFromJson.s.sol
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
Using script Using script /your/path/to/superchain-ops/tasks/sep/metal-002-fp-upgrade/NestedSignFromJson.s.sol
```

This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks **WILL NOT RUN**.
