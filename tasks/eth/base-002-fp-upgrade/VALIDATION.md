# VALIDATION

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Please note, while verifying in Tenderly, you now have to enable the new "Dev Mode" toggle at the top. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c` (The 2/2 `ProxyAdmin` Owner)

Links:
- [Etherscan](https://etherscan.io/address/0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c)

Overrides:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** Enables the simulation by setting the threshold to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

### `0x9855054731540A48b28990B63DcF4f33d8AE46A1` (Base Safe) or `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (Foundation Safe)

Links:
- [Etherscan (Base Safe)](https://etherscan.io/address/0x9855054731540A48b28990B63DcF4f33d8AE46A1). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.
- [Etherscan (Foundation Safe)](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.

The Safe you are signing for will have the following overrides which will set the [Multicall](https://etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11#code) contract as the sole owner of the signing safe. This allows simulating both the approve hash and the final tx in a single Tenderly tx.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The number of owners is set to 1. The key can be validated by the location of the `ownerCount` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L13).

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

The following two overrides are modifications to the [`owners` mapping](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L12). For the purpose of calculating the storage, note that this mapping is in slot `2`.
This mapping implements a linked list for iterating through the list of owners. Since we'll only have one owner (Multicall), and the `0x01` address is used as the first and last entry in the linked list, we will see the following overrides:
- `owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11`
- `owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1`

And we do indeed see these entries:

- **Key:** 0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** This is `owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1`, so the key can be
    derived from `cast index address 0xca11bde05977b3631167028862be2a173976ca11 2`.

- **Key:** 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 <br/>
  **Value:** 0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11 <br/>
  **Meaning:** This is `owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 2`.

## State Changes

**Notes:**
- The value `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` occurs
  multiple times below, and corresponds to the storage key of the implementation address as defined
  in
  [Proxy.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0/packages/contracts-bedrock/src/universal/Proxy.sol#L104)
  and
  [Constants.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0/packages/contracts-bedrock/src/libraries/Constants.sol#L26-L27).


### `0x49048044D57e1C92A77f79988d21Fa8fAF74E97e` (`OptimismPortalProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x49048044D57e1C92A77f79988d21Fa8fAF74E97e)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/21506ecedf6e83410d12c7cc406685ac061a2a74/superchain/configs/mainnet/base.toml#L52)

Upgrades the `OptimismPortal` to the `OptimismPortal2` implementation.

State Changes:
- **Key:** [`0x0000000000000000000000000000000000000000000000000000000000000038`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L80C1-L85C5) <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: [`0x00000000000000000000000043edb88c4b80fdd2adff2412a7bebf9df42cb40e`](https://etherscan.io/address/0x43edb88c4b80fdd2adff2412a7bebf9df42cb40e) <br/>
  **Meaning**: Sets the `DisputeGameFactoryProxy` address in the proxy storage (0x38 is equivalent to 56). Consult the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry/pull/653) for the proxy address value.

- **Key:** [`0x000000000000000000000000000000000000000000000000000000000000003b`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L101C1-L113C5) <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000006716c66800000000` <br/>
  **Meaning**: Sets the `respectedGameType` and `respectedGameTypeUpdatedAt` slot (0x3b is equivalent to 59).
The `respectedGameType` is 32-bits wide at offset 0 which should be set to 0 (i.e. [`CANNON`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28)).
The `respectedGameTypeUpdatedAt` is 64-bits wide and offset by `4` on that slot. It should be equivalent to the unix timestamp of the block the upgrade was executed.
You can extract the offset values from the slot using `chisel`:
```
➜ uint256 x = 0x000000000000000000000000000000000000000000000000664f90d500000000
➜ uint64 respectedGameTypeUpdatedAt = uint64(x >> 32)
➜ respectedGameTypeUpdatedAt
Type: uint64
├ Hex: 0x00000000664f90d5
├ Hex (full word): 0x00000000000000000000000000000000000000000000000000000000664f90d5
└ Decimal: 1716490453
➜
➜ uint32 respectedGameType = uint32(x & 0xFFFFFFFF)
➜ respectedGameType
Type: uint32
├ Hex: 0x
├ Hex (full word): 0x0
└ Decimal: 0
```

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before**: `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589` <br/>
  **After**: [`0x000000000000000000000000e2f826324b2faf99e513d16d266c3f80ae87832b`](https://etherscan.io/address/0xe2f826324b2faf99e513d16d266c3f80ae87832b) <br/>
  **Meaning**: Sets the eip1967 proxy implementation slot to the `OptimismPortal2` implementation.


### `0x73a79Fab69143498Ed3712e519A88a918e1f4072` (`SystemConfigProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x73a79Fab69143498Ed3712e519A88a918e1f4072)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/21506ecedf6e83410d12c7cc406685ac061a2a74/superchain/configs/mainnet/base.toml#L53)

State Changes:
- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1` <br/>
  **After:** [`0x000000000000000000000000f56d96b2535b932656d3c04ebf51babff241d886`](https://etherscan.io/address/0xf56d96b2535b932656d3c04ebf51babff241d886) <br/>
  **Meaning:** This upgrades the SystemConfig implementation. Verify that the new `SystemConfig` implementation is stored at the eip1967 proxy implementation slot.
    Consult the [superchain registry](https://github.com/ethereum-optimism/superchain-registry/blob/804735eef0f0b24fe4287bd1ee3b36c791630923/validation/standard/standard-versions-mainnet.toml#L11C66-L11C106) for the new SystemConfig implementation address.

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: [`0x00000000000000000000000043edb88c4b80fdd2adff2412a7bebf9df42cb40e`](https://etherscan.io/address/43edb88c4b80fdd2adff2412a7bebf9df42cb40e)
  **Meaning**: Sets the [DisputeGameFactory slot](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0/packages/contracts-bedrock/src/L1/SystemConfig.sol#L81-L82). You can verify the correctness of the storage slots with `chisel`. Just start it up and enter the slot definitions as found in the contract source code.
  ```
  ➜ bytes32(uint256(keccak256("systemconfig.disputegamefactory")) - 1)
  Type: bytes32
  └ Data: 0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906
  ```

- **Key**: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
  **Before**: `0x00000000000000000000000056315b90c40730925ec5485cf004d835058518a0`
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **Meaning**: Clears the old and unused [L2OutputOracle slot](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/L1/SystemConfig.sol#L63). You can verify the correctness of the storage slots with `chisel`. Just start it up and enter the slot definitions as found in the contract source code.
  ```
  ➜ bytes32(uint256(keccak256("systemconfig.l2outputoracle")) - 1)
  Type: bytes32
  └ Data: 0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815
  ```


### Safe Contract State Changes

The only other state changes should be restricted to one of the following addresses:

- L1 2/2 ProxyAdmin Owner Safe: `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c`
  - The nonce (slot 0x5) should be increased from 2 to 3.
  - Another key is set from 0 to 1 reflecting an entry in the `approvedHashes` mapping.
- Base L1 Safe: `0x9855054731540A48b28990B63DcF4f33d8AE46A1`
  - The nonce (slot 0x5) should be increased from 14 (0xe) to 15 (0xf).
- Foundation L1 Upgrades Safe: `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`
  - The nonce (slot 0x5) should be increased from 94 to 95.

#### For Base:

- **Key:** `0x20a6c912e89e9f9a3b7b19e820dc2dfa3bdf556756e617efafacf2370e02f763` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by Base. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Base Safe: `0x9855054731540A48b28990B63DcF4f33d8AE46A1`
      - The safe hash to approve: `0x3cf8516a68fc2c37254a100f90774ff8bae325d52d62c70167eed76c6e5413a7`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0x9855054731540A48b28990B63DcF4f33d8AE46A1 8
        0x80e8cf7d2fc4cce32f3c2e9b576f8f3ec9d5ac9c6905f070c54b8d2c07cd3ccd
        ```
        and
      ```shell
        $ cast index bytes32 0x3cf8516a68fc2c37254a100f90774ff8bae325d52d62c70167eed76c6e5413a7 0x80e8cf7d2fc4cce32f3c2e9b576f8f3ec9d5ac9c6905f070c54b8d2c07cd3ccd
        0x20a6c912e89e9f9a3b7b19e820dc2dfa3bdf556756e617efafacf2370e02f763
        ```
      And so the output of the second command matches the key above.

#### For the Foundation:

- **Key:** `0xfd95e97d4d54d0d1ff4424c4c99a89091a555289c0784cc899453daece609757` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by Base. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Foundation Safe: `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`
      - The safe hash to approve: `0x3cf8516a68fc2c37254a100f90774ff8bae325d52d62c70167eed76c6e5413a7`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A 8
        0x7eaa503d7442070af28111802571ddcef5e43630a4ccafa1f94d858abee98ff3
      ```
      and
      ```shell
        $ cast index bytes32 0x3cf8516a68fc2c37254a100f90774ff8bae325d52d62c70167eed76c6e5413a7 0x7eaa503d7442070af28111802571ddcef5e43630a4ccafa1f94d858abee98ff3
        0xfd95e97d4d54d0d1ff4424c4c99a89091a555289c0784cc899453daece609757
      ```
      And so the output of the second command matches the key above.