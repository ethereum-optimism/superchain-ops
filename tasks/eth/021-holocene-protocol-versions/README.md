# Mainnet Required & Recommended Protocol Version Update (9.0.0 - Holocene)
Status: READY TO SIGN

## Objective

This is the playbook to update the required and recommended protocol versions of the `ProtocolVersions` contract on Ethereum mainnet to 9.0.0 (Holocene). It is currently set to 8.0.0 (Granite).

This transaction should be sent on **Jan 7th, 2025**, so 2 days before the [Holocene mainnet activation](https://github.com/ethereum-optimism/superchain-registry/blob/17f539928389cdd88bcae48e6e24c07337ce3f4f/superchain/configs/mainnet/superchain.toml#L11).

The Holocene proposal was:

- [x] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313).
- [x] Approved by Token House voting [here](https://vote.optimism.io/proposals/20127877429053636874064552098716749508236019236440427814457915785398876262515).
- [ ] Not vetoed by the Citizens' house
- [ ] Executed on OP Mainnet.

The [governance proposal](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313) should be treated as the source of truth and used to verify the correctness of the onchain operations.

## Deployments

* Mainnet: [`0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935`](https://github.com/ethereum-optimism/superchain-registry/blob/17f539928389cdd88bcae48e6e24c07337ce3f4f/superchain/configs/mainnet/superchain.toml#L2)

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/021-holocene-protocol-versions/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execution" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).

When executing, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/021-holocene-protocol-versions/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.
