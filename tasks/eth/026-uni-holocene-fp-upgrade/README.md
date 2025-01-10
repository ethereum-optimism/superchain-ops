# Holocene Hardfork Upgrade

Status: DRAFT, NOT READY TO SIGN

## Objective

Upgrades the **Unichain Mainnet** Fault Proof contracts for the Holocene hardfork.

The proposal was:

- [X] [Posted](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313) on the governance forum.
- [X] [Approved](https://vote.optimism.io/proposals/20127877429053636874064552098716749508236019236440427814457915785398876262515) by Token House voting.
- [X] Not vetoed by the Citizens' house.
- [X] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2fv1.8.0) release.

This upgrade uses a custom absolute prestate create by Unichain that is not part of an official release yet:
`0x0336751a224445089ba5456c8028376a0faf2bafa81d35f43fab8730258cdf37`.

The `FaultDisputeGame` is a fresh deployment for game type 0, so it's not checked against a previous deployment's values.

The `PermissionedDisputeGame` is redeployed with a new challenger, the [Optimism Foundation challenger](https://github.com/ethereum-optimism/superchain-registry/blob/c08331ab44a3645608c08d8c94f78d9be46c13c9/validation/standard/standard-config-roles-mainnet.toml#L7) `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`.

The AnchorStateRegistry is reinitialized to
`(0xb5e152a45892717ad881031078cf0af24d224188cdaf1b16fcdba9657423c997,5619555)`
and the bond sizes are updated to 0.08 ETH.

## Pre-deployments

- `MIPS` - `0x5fE03a12C1236F9C22Cb6479778DDAa4bce6299C`
- `FaultDisputeGame` - `0x08f0F8F4E792d21E16289dB7a80759323C446F61`
- `PermissionedDisputeGame` - `0xC457172937fFa9306099ec4F2317903254Bf7223`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/026-uni-holocene-fp-upgrade/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Reinitializes the `AnchorStateRegistry` with a new starting output root.
* Changes dispute game implementation of the `CANNON` and `PERMISSIONED_CANNON` game types to contain a `op-program` release for the Holocene hardfork, which contains
  the Holocene fork implementation as well as a `ChainConfig` and `RollupConfig` for the L2 chain being upgraded.
* Upgrades `MIPS.sol` to support the `F_GETFD` syscall, required by the golang 1.22+ runtime. This
  upgrade is implicit in that the newly deployed game implementations point to the new MIPS deployment.
* Sets the initial bond sizes for both game types to **0.08 ETH**.

See the `input.json` bundle for more details.

## Preparation Notes

The following notes are just for future reference on how this task was prepared.

### Anchor State Registry

The two anchor state reinitialization txs were prepared using the following `cast` magic ✨

```sh
export ETH_RPC_URL=<mainnet-l1-rpc>
asr_proxy=$(yq .addresses.AnchorStateRegistryProxy uni.toml)
asr_impl=$(cast call $asr_proxy 'implementation()(address)')

# Craft storage setter clearing upgrade
storage_setter="0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC"
zero32=$(cast tb 0)
# slot 0 stores initialized flag, see packages/contracts-bedrock/snapshots/storageLayout/AnchorStateRegistry.json
clear_call=$(cast calldata 'setBytes32(bytes32,bytes32)' $zero32 $zero32)

# Craft proxy upgrade call to clear as 1st tx in bundle
cast calldata 'upgradeAndCall(address,address,bytes)' $asr_proxy $storage_setter $clear_call


# Get the output root for the latest finalized block number
export ETH_RPC_URL=https://unichain-opn-geth-a-rpc-0-op-node.optimism.io/ # or another uni mainnet op-node
block_num=$(cast rpc optimism_syncStatus | jq .finalized_l2.number)
output_root=$(cast rpc optimism_outputAtBlock $(cast th $block_num) | jq -r .outputRoot)

# Craft a ASR initialize transaction - used as data argument to upgradeAndCall
superchain_config_proxy=$(yq .superchain_config_addr $(git rev-parse --show-toplevel)/lib/superchain-registry/superchain/configs/mainnet/superchain.toml)
initialize_call=$(cast calldata 'initialize((uint32,(bytes32,uint256))[] _startingAnchorRoots, address _superchainConfig)' '[(0,('$output_root,$block_num')),(1,('$output_root,$block_num'))]' $superchain_config_proxy)

# Craft proxy upgrade call to re-initialize as 2nd tx in bundle
cast calldata 'upgradeAndCall(address,address,bytes)' $asr_proxy $asr_impl $initialize_call
```
