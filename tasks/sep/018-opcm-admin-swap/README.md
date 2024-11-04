# Sepolia OPCM Admin Swap

Status: DRAFT, NOT READY TO SIGN

## Objective

Changes the admin/owner address of the `OPContractsManager` proxy contract on Sepolia to be the
`ProxyAdmin` contract on Sepolia instead of the 2/2 Safe. This configuration matches the setup on
Ethereum and guarantees that we continue a consistent pattern of having the `ProxyAdmin` own
`Proxy` contracts everywhere.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/018-opcm-admin-swap/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade changes the admin/owner of the `OPContractsManager` contract from the current value of
`0xF564eEA7960EA244bfEbCBbB17858748606147bf` to the updated value of
`0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc`, the current `ProxyAdmin` contract for OP Sepolia.
This is the only modification made by this upgrade.

The batch will be executed on chain ID `11155111`, and contains `1` transaction.

See the input.json bundle for more details.
