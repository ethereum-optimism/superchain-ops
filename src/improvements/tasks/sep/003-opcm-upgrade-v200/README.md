# 003-opcm-upgrade-v200: Sepolia OPCM v2.0.0: Unichain

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x27f588c544e0b87868228b161848334903e689019a7fb3f95c10fb327a21c10a)

## Objective

Executes [Upgrade 13](https://gov.optimism.io/t/upgrade-proposal-13-opcm-and-incident-response-improvements/9739) on Unichain Sepolia Testnet.

In summary, this task uses `op-contract/v2.0.0` [OPContractsManager](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/L1/OPContractsManager.sol) to upgrade 1 chain:
1. Unichain Sepolia Testnet

### Timing

Expected to be executed on or around 2025-03-28.

## Transaction creation

The transaction is generated by the [OPCMV200 template script](../../../template/OPCMUpgradeV200.sol),
which reads the inputs from the [`config.toml`](./config.toml) file.

## Signing and execution

Follow the instructions in the [Single Execution](../../../SINGLE.md) guide for the following steps:

- [1. Update repo](../../../SINGLE.md#1-update-repo)
- [2. Setup Ledger](../../../SINGLE.md#2-setup-ledger)
- [3. Simulate and validate the transaction](../../../SINGLE.md#3-simulate-and-validate-the-transaction)

Then follow the instructions in the [Validation](./VALIDATION.md) guide.

## Simulation

When simulating, ensure the logs say `Using script <your_path_to_superchain_ops>/superchain-ops/src/improvements/template/OPCMUpgradeV200.sol`.
Navigate to the correct task directory then run the simulate command.
```
cd 003-opcm-upgrade-v200
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```
