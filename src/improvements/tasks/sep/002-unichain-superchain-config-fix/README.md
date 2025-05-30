
# 002-unichain-superchain-config-fix: Unichain Sepolia SuperchainConfig fix

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x8f1bf1fb5acdadf0575f999af12c23701f0840d03a98ad832afefc6e78f0a4de)

## Objective

This task reinitializes Unichain Sepolia's L1 system contracts so they all point to the shared SuperchainConfig implementation target on Sepolia.

Unichain Sepolia currently uses a non-standard SuperchainConfig. Until this task is completed, Unichain Sepolia is blocked from doing U13+ using OPCM because OPCM assumes the chain is part of the Superchain.

## Transaction creation

The transaction is generated by the [UniFix script](../../../template/UniFix.sol), which reads the inputs from the [`config.toml`](./config.toml) file.

## Signing and execution

Follow the instructions in the [Single Execution](../../../SINGLE.md) guide for the following steps:

- [1. Update repo](../../../SINGLE.md#1-update-repo)
- [2. Setup Ledger](../../../SINGLE.md#2-setup-ledger)
- [3. Simulate and validate the transaction](../../../SINGLE.md#3-simulate-and-validate-the-transaction)

Then follow the instructions in the [Validation](./VALIDATION.md) guide.

## Simulation

When simulating, ensure the logs say `Using script <your_path_to_superchain_ops>/superchain-ops/src/improvements/template/UniFix.sol`.
Navigate to the correct task directory then run the simulate command.
```
cd 002-unichain-superchain-config-fix
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
# Optionally set the SIGNER_ADDRESS environment variable to simulate as a specific address. Or remove SIMULATE_WITHOUT_LEDGER to simulate with Ledger. e.g. To set a custom signer: SIMULATE_WITHOUT_LEDGER=1 SIGNER_ADDRESS=0x1111111111111111111111111111111111111111
```
