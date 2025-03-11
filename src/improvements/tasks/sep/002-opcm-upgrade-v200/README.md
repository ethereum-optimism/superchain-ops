# 002-opcm-upgrade-v200: Sepolia OPCM v2.0.0: Unichain

Status: [DRAFT]()

## Objective

- Governance Post (mainnet): [Upgrade Proposal #13: OPCM and Incident Response improvements](https://gov.optimism.io/t/upgrade-proposal-13-opcm-and-incident-response-improvements/9739)

In summary, this task uses `op-contract/v2.0.0` [OPContractsManager](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/L1/OPContractsManager.sol) to upgrade 1 chain:
1. Unichain Sepolia Testnet

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Simulation

When simulating, ensure the logs say `Using script <your_path_to_superchain_ops>/superchain-ops/src/improvements/template/OPCMUpgradeV200.sol`.
Navigate to the correct task directory then run the simulate command.
```
cd 002-opcm-upgrade-v200
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../single.just simulate
```




