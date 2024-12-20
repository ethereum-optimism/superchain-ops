# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transactions.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the simulation is
- Council simulation: `0xca167e305357972ad4bb8d1353a317081afef9619b4f62f7173b0a2c18a5641b`
- Foundation simulation: `0xb6dd08d9ebb19e58638adf5c77f5bafb0340199b1b0e88b6cc82442a99461b73`

calculated as explained in the nested validation doc:
```sh
SAFE_HASH=0xbf85fbc223d92f056c8a48975db99c6b2153fbcf78d6c48109ef9774c6e272a6 # "Nested hash:"
SAFE_ROLE=0x9855054731540A48b28990B63DcF4f33d8AE46A1 # "Council" - Base
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0xca167e305357972ad4bb8d1353a317081afef9619b4f62f7173b0a2c18a5641b

SAFE_ROLE=0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A # Foundation Operations Safe
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0xb6dd08d9ebb19e58638adf5c77f5bafb0340199b1b0e88b6cc82442a99461b73
```

## State Changes

### `0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0xCd3c0194db74C23807D4B90A5181e1B28cF7007C` <br/>
  **After**: `0xc5f3677c3C56DB4031ab005a3C9c98e1B79D438e` <br/>
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0xCd3c0194db74C23807D4B90A5181e1B28cF7007C`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x19009dEBF8954B610f207D5925EEDe827805986e` <br/>
  **After**: `0xF62c15e2F99d4869A925B8F57076cD85335832A2` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0x43edB88C4B80fDD2AdFF2412A7BebF9dF42cB40e "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).
  Before this task has been executed, you will see that the returned address is `0x19009dEBF8954B610f207D5925EEDe827805986e`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.
