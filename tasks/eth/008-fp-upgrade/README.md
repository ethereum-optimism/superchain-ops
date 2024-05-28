# Mainnet Fault Proofs Upgrade

STATUS: DRAFT DO NOT EXECUTE
## Objective

This is the playbook for executing the Fault Proofs upgrade on Mainnet.

This deploys the v1.4.0-rc.4 set of contracts, which includes Fault Proofs. Refer to the [release notes](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.4.0-rc.4) for the contract changes.

Governance post of the Fault Proofs upgrade can be found at https://gov.optimism.io/t/upgrade-proposal-fault-proofs/8161.

1. Upgrades the `OptimismPortal` proxy implementation.
1. Upgrades the `SystemConfig` proxy implementation.

Details on the upgrade procedure can be found in [EXEC.md](./EXEC.md). Signers need not validate the, but they are provided for reference.

## Preparing the Upgrade

The contract implementations and new proxies for the Fault Proof system have been pre-deployed to mainnet.

- `AnchorStateRegistry`: `0x6B7da1647Aa9684F54B2BEeB699F91F31cd35Fb9`,
- `AnchorStateRegistryProxy`: `0x18DAc71c228D1C32c99489B7323d441E1175e443`,
- `DelayedWETH`: `0x97988d5624F1ba266E1da305117BCf20713bee08`
- `DelayedWETHProxy`: `0xE497B094d6DbB3D5E4CaAc9a14696D7572588d14`
- `DisputeGameFactory`: `0xc641A33cab81C559F2bd4b21EA34C290E2440C2B`
- `DisputeGameFactoryProxy`: `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`
- `FaultDisputeGame`: `0x4146DF64D83acB0DcB0c1a4884a16f090165e122`
- `Mips`: `0x0f8EdFbDdD3c0256A80AD8C0F2560B1807873C9c`
- `OptimismPortal2`: `0xe2F826324b2faf99E513D16D266c3F80aE87832B`
- `PermissionedDisputeGame`: `0xE9daD167EF4DE8812C1abD013Ac9570C616599A0`
- `PreimageOracle`: `0xD326E10B8186e90F4E2adc5c13a2d0C137ee8b34`
- `SystemConfig`: `0xF56D96B2535B932656d3c04Ebf51baBff241D886`

All that's left is to execute the upgrade.


## Signing and execution

Please see the signing and execution instructions in [NESTED.md](../../../NESTED.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
