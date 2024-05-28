# Sepolia Upgrade L2 Predeploy From L1 - No-op

Status: EXECUTED: [L1 Transaction](https://sepolia.etherscan.io/tx/0xec60a5201ba59157bbda2f515d4e35993b2106a95ee0593e6502b34d2cb15653) and [L2 Transaction](https://sepolia-optimism.etherscan.io/tx/0x3dd74dd7745fa2f10c3708b57809249aac5c38c17cd50c3c961734407b35c1a6)

## Objective

This is the Sepolia playbook for performing an L2 predeploy upgrade using the L1 Proxy Admin Owner. The exact upgrade will be a **no-op**, meaning we will upgrade a predeploy to the same implementation address it is already pointing to. This approach will allow us to confirm that predeploy upgrades on L2 work using a transaction originating from L1.
Ultimately, having the security council have veto power over L2 predeploy upgrades is a [requirement](https://gov.optimism.io/t/upgrade-proposal-guardian-security-council-threshold-and-l2-proxyadmin-ownership-changes-for-stage-1-decentralization/8157) for reaching Stage 1. The security council is a signer on the L1 Proxy Admin Owner.


The success criteria involve verifying that the dummy upgrade occurred on L2 by looking for an emitted [Upgraded event](https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/universal/Proxy.sol#L108) and, prior to this, confirming that a `TransactionDeposited` event was emitted from the `OptimismPortal` on L1.

The no-op is upgrading the L2ERC721Bridge [0x4200000000000000000000000000000000000014](https://sepolia-optimism.etherscan.io/address/0x4200000000000000000000000000000000000014) to it's current implementation code [0xc0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30014](https://sepolia-optimism.etherscan.io/address/0xc0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30014#code).


## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/010-op-l2-predeploy-upgrade-from-l1/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [NESTED.md](../../../NESTED.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/sep/010-op-l2-predeploy-upgrade-from-l1/NestedSignFromJson.s.sol`. This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
