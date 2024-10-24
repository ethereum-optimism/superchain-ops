# Base Mainnet Fault Proofs Upgrade

Status: [READY TO SIGN]

## Objective

This playbook upgrades Base Mainnet to use the permissionless fault proofs system.

The Base team has already deployed and tested the fault proof contract set. Refer to the [release notes](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.6.0) for the contract release details.

Governance post of the Fault Proofs upgrade can be found at https://gov.optimism.io/t/upgrade-proposal-10-granite-network-upgrade/8733.

1. Upgrades the `OptimismPortal` proxy implementation.
2. Upgrades the `SystemConfig` proxy implementation.

Details on the upgrade procedure can be found in [EXEC.md](./EXEC.md). Signers need not validate the, but they are provided for reference.

## Preparing the Upgrade

The contract implementations and new proxies for the Fault Proof system have been pre-deployed to mainnet.

- `AnchorStateRegistry`: `0x60F1Ea7B3359a4008655df44560B6899B1877a15`,
- `AnchorStateRegistryProxy`: `0xdB9091e48B1C42992A1213e6916184f9eBDbfEDf`,
- `DelayedWETH`: `0x71e966ae981d1ce531a7b6d23dc0f27b38409087`
- `DelayedWETHProxy`: ``
- `DisputeGameFactory`: `0xc641a33cab81c559f2bd4b21ea34c290e2440c2b`
- `DisputeGameFactoryProxy`: `0x43edb88c4b80fdd2adff2412a7bebf9df42cb40e`
- `FaultDisputeGame`: `0xCd3c0194db74C23807D4B90A5181e1B28cF7007C`
- `Mips`: `0x0f8EdFbDdD3c0256A80AD8C0F2560B1807873C9c`
- `OptimismPortalProxy`: `0x49048044D57e1C92A77f79988d21Fa8fAF74E97e`
- `PermissionedDisputeGame`: `0x19009dEBF8954B610f207D5925EEDe827805986e`
- `PreimageOracle`: `0x9c065e11870B891D214Bc2Da7EF1f9DDFA1BE277`
- `SystemConfig`: `0x73a79Fab69143498Ed3712e519A88a918e1f4072`

All that's left is to execute the upgrade.


## Signing and execution

Please see the signing and execution instructions in [NESTED.md](../../../NESTED.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
