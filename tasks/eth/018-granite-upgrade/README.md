# Mainnet Granite Upgrade + Fault Proof Fixes

Status: [EXECUTED](https://etherscan.io/tx/0x3bd2d811d0298313e6fb75f0e69fb54280c9b4f2e60f8f04472aaa166c285641)

## Objective

This is a playbook for upgrading Fault Proofs on Mainnet for Granite compatibility.

This patch also upgrades Fault Proof contracts to fix issues found highlighted by various audits.

The proposal was:

- [x] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-10-granite-network-upgrade/8733).
- [x] Approved by Token House voting [here](https://vote.optimism.io/proposals/46514799174839131952937755475635933411907395382311347042580299316635260952272).
- [x] Not vetoed by the Citizens' house [here](https://snapshot.org/#/citizenshouse.eth/proposal/0xb0c109d7f68d3cb1054a50f55556d1820e517129b4b53774cb9ca32e0eabe3a4).
- [ ] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

Governance post of the upgrade can be found at https://gov.optimism.io/t/upgrade-proposal-10-granite-network-upgrade/8733.

This upgrades the Fault Proof contracts in the [op-contracts/v1.6.0](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.6.0-rc.3) release.


## Pre-deployments

Verify their addresses in this section of the [governance proposal](https://gov.optimism.io/t/upgrade-proposal-10-granite-network-upgrade/8733#p-39463-impacted-components-8).

- `FaultDisputeGame` - [`0xA6f3DFdbf4855a43c529bc42EDE96797252879af`](https://etherscan.io/address/0xA6f3DFdbf4855a43c529bc42EDE96797252879af).
- `PermissionedDisputeGame` - [`0x050ed6F6273c7D836a111E42153BC00D0380b87d`](https://etherscan.io/address/0x050ed6F6273c7D836a111E42153BC00D0380b87d).
- `AnchorStatRegistry` - [`0x1B5CC028A4276597C607907F24E1AC05d3852cFC`](https://etherscan.io/address/0x1B5CC028A4276597C607907F24E1AC05d3852cFC).
- `StorageSetter` - [`0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC`](https://etherscan.io/address/0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC).
- `DelayedWETH` - [`0x71e966Ae981d1ce531a7b6d23DC0f27B38409087`](https://etherscan.io/address/0x71e966Ae981d1ce531a7b6d23DC0f27B38409087)
- `DelayedWETHProxy` - [`0x82511d494B5C942BE57498a70Fdd7184Ee33B975`](https://etherscan.io/address/0x82511d494B5C942BE57498a70Fdd7184Ee33B975)
- `PermissionedDelayedWETHProxy` - [`0x9F9b897e37de5052cD70Db6D08474550DDb07f39`](https://etherscan.io/address/0x9F9b897e37de5052cD70Db6D08474550DDb07f39)
- `PreimageOracle` - [`0x9c065e11870B891D214Bc2Da7EF1f9DDFA1BE277`](https://etherscan.io/address/0x9c065e11870B891D214Bc2Da7EF1f9DDFA1BE277)
- `MIPS` - [`0x16e83cE5Ce29BF90AD9Da06D2fE6a15d5f344ce4`](https://etherscan.io/address/0x16e83cE5Ce29BF90AD9Da06D2fE6a15d5f344ce4)

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/018-granite-upgrade/NestedSignFromJson.s.sol`. This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## Signing and execution

Please see the signing and execution instructions in [NESTED.md](../../../NESTED.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
