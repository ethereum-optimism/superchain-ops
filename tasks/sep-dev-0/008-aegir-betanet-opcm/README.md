# Aegir Betanet Upgrade

Status:

## Objective

Run the OPCM upgrade path against the [Aegir Betanet](https://github.com/ethereum-optimism/devnets/blob/main/betanets/aegir).
The Aegir betanet is configured  with two OP Chains ([aegir-0](https://github.com/ethereum-optimism/devnets/blob/main/betanets/aegir/aegir-0/chain.yaml) and [aegir-1](https://github.com/ethereum-optimism/devnets/blob/main/betanets/aegir/aegir-1/chain.yaml)).

Aegir-0 has only the permissioned game enabled. Aegir-1 has both games.

The system was deployed with contracts on the Holocene version. An OPCM and new implementations
were subsequently deployed from the monorepo at [a79e8cc](https://github.com/ethereum-optimism/optimism/commit/a79e8cc06aa354511983fafcb6d71ab04cdfadbc) on the
`develop` branch.

## Pre-deployments

```json
{
  "Opcm": "0x81395ec06f830a3b83fe64917893193380a58d11",
  "DelayedWETHImpl": "0x5e40b9231b86984b5150507046e354dbfbed3d9e",
  "OptimismPortalImpl": "0x6033abbb8494dc57659aee4a7d4cd26948f46968",
  "PreimageOracleSingleton": "0xae225b2accc35e8be115c585d1485a80859f96d4",
  "MipsSingleton": "0x738912d0a68ce3123501f067c61c048f64632e38",
  "SystemConfigImpl": "0x760c48c62a85045a6b69f07f4a9f22868659cbcc",
  "L1CrossDomainMessengerImpl": "0x3ea6084748ed1b2a9b5d4426181f1ad8c93f6231",
  "L1ERC721BridgeImpl": "0x4d346291ec479e4ad1e3dddef5a7690c5afb9bee",
  "L1StandardBridgeImpl": "0x56b5fd615cbc2c094a84eb6547f98e656ebc1daa",
  "OptimismMintableERC20FactoryImpl": "0x5493f4677a186f64805fe7317d6993ba4863988f",
  "DisputeGameFactoryImpl": "0x4bba758f006ef09402ef31724203f316ab74e4a0",
  "AnchorStateRegistryImpl": "0x70023a9d23b074f0c4f1cbb4ff63a87369a17abf",
  "SuperchainConfigImpl": "0x4da82a327773965b8d4d85fa3db8249b387458e7",
  "ProtocolVersionsImpl": "0x37e15e4d6dffa9e5e320ee1ec036922e563cb76c"
}
```

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep-dev-0/008-aegir-betanet-opcm/`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes dispute game implementation of the `CANNON` and `PERMISSIONED_CANNON` game types to contain a `op-program` release for the Holocene hardfork, which contains
  the Holocene fork implementation as well as a `ChainConfig` and `RollupConfig` for the L2 chain being upgraded.
* Upgrades `MIPS.sol` to support the `F_GETFD` syscall, required by the golang 1.22+ runtime.

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
