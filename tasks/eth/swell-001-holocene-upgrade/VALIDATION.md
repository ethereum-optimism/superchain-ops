# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the below hashes match what is on your ledger.
> ### Security Council
> - Domain hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message hash: `0x0d975c956fd25be3f8303b3ed3c60bafecaf45ce80ffc0744e4f585b83852e1e`
> ### Optimism Foundation
> - Domain hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message hash: `0x7f326067f1fd183dfd22efb1b67cc88afdf2acd2ce22d8d1816611bfaeb5f7fe`


## Verify new absolute prestate
The following is based on the **op-program/v1.6.0-rc.1**: \
Absolute prestates can be checked in the Superchain Registry [standard-prestates.toml](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml). 

Please, verify that the new absolute prestate is set correctly to `0x03526dfe02ab00a178e0ab77f7539561aaf5b5e3b46cd3be358f1e501b06d8a9`. \
See [Pectra notice](https://docs.optimism.io/notices/pectra-changes#verify-the-new-absolute-prestate) in docs for more details. \
To manually verify the prestate `0x03526dfe02ab00a178e0ab77f7539561aaf5b5e3b46cd3be358f1e501b06d8a9`, based on **op-program/v1.6.0-rc.1**, run the below command in the root of https://github.com/ethereum-optimism/optimism/tree/op-program/v1.6.0-rc.1:

You can verify this absolute prestate by running the following [command](https://github.com/ethereum-optimism/optimism/blob/6819d8a4e787df2adcd09305bc3057e2ca4e58d9/Makefile#L133-L135) in the root of the monorepo:

```bash
make reproducible-prestate
```

You should expect the following output at the end of the command:

```bash
Cannon Absolute prestate hash: 
0x03526dfe02ab00a178e0ab77f7539561aaf5b5e3b46cd3be358f1e501b06d8a9
Cannon64 Absolute prestate hash: 
0x03394563dd4a36e95e6d51ce7267ecceeb05fad23e68d2f9eed1affa73e5641a
CannonInterop Absolute prestate hash: 
0x03ada038f8a81526c68596586dfc762eb5412d4d5bb7cb46110d8c47ee570d7e
```

## State Overrides

The following state overrides should be seen:

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council Safe)
| **Key** | `0x0000000000000000000000000000000000000000000000000000000000000005` |
|---------|----------------------------------------------------------------------------------|
| **After** | `0x000000000000000000000000000000000000000000000000000000000000001c` |

**Meaning:** Override the nonce value of the `Security Council` by increasing from 27 to 28.


### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Upgrade Safe)
 | **Key** | `0x0000000000000000000000000000000000000000000000000000000000000005` |
 |---------|----------------------------------------------------------------------------------|
 | **After** | `0x000000000000000000000000000000000000000000000000000000000000001b` |

**Meaning:** Override the nonce value of the Foundation Upgrade Safe by increasing from 26 to 27.


### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO Safe)
| **Key** | `0x0000000000000000000000000000000000000000000000000000000000000005` |
|---------|----------------------------------------------------------------------------------|
| **After** | `0x0000000000000000000000000000000000000000000000000000000000000010` |

**Meaning:** Override the nonce value of the L1PAO by increasing from 15 to 16.


Links:
- [Etherscan (Council Safe)](https://etherscan.io/address/0xc2819DC788505Aac350142A7A707BF9D03E3Bd03). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.
- [Etherscan (Foundation Safe)](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.

The Safe you are signing for will have the following overrides which will set the [Multicall](https://etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11#code) contract as the sole owner of the signing safe. This allows simulating both the approve hash and the final tx in a single Tenderly tx.

| **Key** | `0x0000000000000000000000000000000000000000000000000000000000000003` |
|---------|----------------------------------------------------------------------------------|
| **Value** | `0x0000000000000000000000000000000000000000000000000000000000000001` |
| **Meaning** | The number of owners is set to 1. The key can be validated by the location of the `ownerCount` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L13). |

| **Key** | `0x0000000000000000000000000000000000000000000000000000000000000004` |
|---------|----------------------------------------------------------------------------------|
| **Value** | `0x0000000000000000000000000000000000000000000000000000000000000001` |
| **Meaning** | The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14). |

| **Key** | `0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c` |
|---------|----------------------------------------------------------------------------------|
| **Value** | `0x0000000000000000000000000000000000000000000000000000000000000001` |
| **Meaning** | This is `owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1`, so the key can be derived from `cast index address 0xca11bde05977b3631167028862be2a173976ca11 2`. |

| **Key** | `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` |
|---------|----------------------------------------------------------------------------------|
| **Value** | `0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11` |
| **Meaning** | This is `owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11`, so the key can be derived from `cast index address 0x0000000000000000000000000000000000000001 2`. |


## State Changes

Note: The changes listed below do not include safe nonce updates or liveness guard related changes.

### `0x87690676786cDc8cCA75A472e483AF7C8F2f0F57` (`DisputeGameFactoryProxy`)
 | **Key** | `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` |
 |---------|----------------------------------------------------------------------------------|
 | **Before** | `0x000000000000000000000000a0cfbe3402d6e0a74e96d3c360f74d5ea4fa6893` |
 | **After** | `0x0000000000000000000000001380cc0e11bfe6b5b399d97995a6b3d158ed61a6` |
> [!NOTE]  
> **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. You can verify which implementation is set using `cast call 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57 "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31). \
  Before this task has been executed, you will see that the returned address is `0x000000000000000000000000a0cfbe3402d6e0a74e96d3c360f74d5ea4fa6893`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.



 | **Key** | `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` |
 |---------|----------------------------------------------------------------------------------|
 | **Before** | `0x0000000000000000000000000000000000000000000000000000000000000000` |
 | **After** | `0x0000000000000000000000002DabFf87A9a634f6c769b983aFBbF4D856aDD0bF` |
 > [!NOTE]  
  **Meaning**: Updates the CANNON game type implementation. You can verify which implementation is set using `cast call 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57 "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
  Before this task has been executed, you will see that the returned address is `0x0000000000000000000000000000000000000000000000000000000000000000`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.



