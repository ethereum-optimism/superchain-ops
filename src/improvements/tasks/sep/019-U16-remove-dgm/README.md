# 019-U16-remove-dgm: Remove Deputy Guardian Module on Sepolia

Status: [DRAFT]()

## Objective

### Timing

Expected to be executed on or around 2025-05-29.

## Transaction creation


## Signing and execution

Follow the instructions in the [Nested Execution](../../../NESTED.md) guide for the following steps:

- [1. Update repo](../../../NESTED.md#1-update-repo)
- [2. Setup Ledger](../../../NESTED.md#2-setup-ledger)
- [3. Simulate and validate the transaction](../../../NESTED.md#3-simulate-and-validate-the-transaction)

Then follow the instructions in the [Validation](./VALIDATION.md) guide.

## Simulation

SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../nested.just simulate foundation