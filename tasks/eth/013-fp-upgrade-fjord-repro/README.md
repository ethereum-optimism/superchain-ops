# Mainnet Fjord Fault Proofs Upgrade

Status: [EXECUTED](https://etherscan.io/tx/0x7abecacd8b1a54db8f0835a5c82edfab96ff922a41d2faa914c339e3e9319b43)

## Objective

This is a playbook for upgrading Fault Proofs on Mainnet for Fjord compatibility.

This sets the `FaultDisputeGame` and `PermissionedDisputeGame` implementations in the `DisputeGameFactory` to newly deployed contracts that have an updated prestate.

The proposal was:

- [x] Posted on the governance forum [here](https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236).
- [x] Approved by Token House voting [here](https://vote.optimism.io/proposals/19894803675554157870919000647998468859257602050917884642551010462863037711179).
- [x] Not vetoed by the Citizens' house [here](https://snapshot.org/#/citizenshouse.eth/proposal/0x14336dfcb086279e47ef8fffbd6282984d392f1b9eaf22f76547210df6451c43).
- [x] [Executed on OP Sepolia](https://github.com/ethereum-optimism/superchain-ops/tree/main/tasks/sep/011-fjord-upgrade).

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

Governance post of the upgrade can be found at https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236.

Details on the upgrade procedure can be found in [EXEC.md](./EXEC.md). Signers need not validate the, but they are provided for reference.

## Preparing the Upgrade

The new Fault Dispute Game contract implementations have been pre-deployed to mainnet.

- `FaultDisputeGame`: [`0xf691F8A6d908B58C534B624cF16495b491E633BA`](https://etherscan.io/address/0xc307e93a7C530a184c98EaDe4545a412b857b62f)
- `PermissionedDisputeGame` - [`0xc307e93a7C530a184c98EaDe4545a412b857b62f`](https://etherscan.io/address/0xc307e93a7C530a184c98EaDe4545a412b857b62f)

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/013-fp-upgrade-fjord/NestedSignFromJson.s.sol`. This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## Signing and execution

Please see the signing and execution instructions in [NESTED.md](../../../NESTED.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
