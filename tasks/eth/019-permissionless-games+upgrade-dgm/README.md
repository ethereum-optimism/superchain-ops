# Deputy Guardian - Reset back to permissionless Cannon `FaultDisputeGame`

Status: READY TO SIGN

## Objective

This batch performs the following:

- Updates the `respectedGameType` to `CANNON` in the `OptimismPortalProxy`. This action requires all in-progress withdrawals to be re-proven against a new permissionless Cannon `FaultDisputeGame` that was created after this update occurs.
- Upgrades the `DeputyGuardianModule` as part of the Fault Proof fixes for the Granite protocol upgrade.

Read the [Granite upgrade proposal](https://gov.optimism.io/t/upgrade-proposal-10-granite-network-upgrade/8733#p-39463-additional-fixes-7) (see the "Additional fixes" section) for more details.

The governance proposal was:

- [x] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-10-granite-network-upgrade/8733).
- [x] Approved by Token House voting [here](https://vote.optimism.io/proposals/46514799174839131952937755475635933411907395382311347042580299316635260952272).
- [x] Not vetoed by the Citizens' house [here](https://snapshot.org/#/citizenshouse.eth/proposal/0xb0c109d7f68d3cb1054a50f55556d1820e517129b4b53774cb9ca32e0eabe3a4).
- [ ] Executed on OP Mainnet.

The batch will be executed on chain ID `1`, and contains `3` transactions.

This batch must be executed after Granite activates on mainnet on **Wed 11 Sep 2024 16:00:01 UTC**.

## Pre-deployments

- `DeputyGuardianModule` - [`0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B`](https://etherscan.io/address/0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B)


## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/019-permissionless-games+upgrade-dgm/SignFromJson.s.sol`. This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## Signing and execution

Please see the signing and execution instructions in [SINGLE.md](../../../SINGLE.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
