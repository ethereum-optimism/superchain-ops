# VALIDATION

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

**Notes:**
- The value `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` occurs
  multiple times below, and corresponds to the storage key of the implementation address as defined
  in
  [Proxy.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/src/universal/Proxy.sol#L104)
  and
  [Constants.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/src/libraries/Constants.sol#L26-L27).

### `0x229047fed2591dbec1ef1118d64f7af3db9eb290` (`SystemConfigProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x229047fed2591dbec1eF1118d64F7aF3dB9EB290)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/94149a2651f0aadb982802c8909d60ecae67e050/superchain/extra/addresses/mainnet/op.json#L10)

State Changes:
- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1` <br/>
  **After:** [`0x000000000000000000000000f56d96b2535b932656d3c04ebf51babff241d886`](https://etherscan.io/address/0xf56d96b2535b932656d3c04ebf51babff241d886) <br/>
  **Meaning:** This upgrades the SystemConfig implementation. Verify that the new `SystemConfig` implementation is stored at the eip1967 proxy implementation slot.
    Consult the [gov proposal](https://gov.optimism.io/t/final-protocol-upgrade-7-fault-proofs/8161) for the new SystemConfig implementation address.

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: [`0x000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa9`](https://etherscan.io/address/0xe5965ab5962edc7477c8520243a95517cd252fa9)
  **Meaning**: Sets the [DisputeGameFactory slot](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/src/L1/SystemConfig.sol#L76). You can verify the correctness of the storage slots with `chisel`. Just start it up and enter the slot definitions as found in the contract source code.
  ```
  ➜ bytes32(uint256(keccak256("systemconfig.disputegamefactory")) - 1)
  Type: bytes32
  └ Data: 0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906
  ```

- **Key**: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
  **Before**: `0x000000000000000000000000dfe97868233d1aa22e815a266982f2cf17685a27`
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **Meaning**: Clears the old and unused [L2OutputOracle slot](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/L1/SystemConfig.sol#L63). You can verify the correctness of the storage slots with `chisel`. Just start it up and enter the slot definitions as found in the contract source code.
  ```
  ➜ bytes32(uint256(keccak256("systemconfig.l2outputoracle")) - 1)
  Type: bytes32
  └ Data: 0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815
  ```


### `0xbeb5fc579115071764c7423a4f12edde41f106ed` (`OptimismPortalProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0xbEb5Fc579115071764c7423A4f12eDde41f106Ed)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L8)

Upgrades the `OptimismPortal` to the `OptimismPortal2` implementation.

State Changes:
- **Key:** [`0x0000000000000000000000000000000000000000000000000000000000000038`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L80C1-L85C5) <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: [`0x000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa9`](https://etherscan.io/address/0xe5965ab5962edc7477c8520243a95517cd252fa9) <br/>
  **Meaning**: Sets the `DisputeGameFactoryProxy` address in the proxy storage (0x38 is equivalent to 56). Consult the [gov proposal](https://gov.optimism.io/t/final-protocol-upgrade-7-fault-proofs/8161) for the proxy address value.

- **Key:** [`0x000000000000000000000000000000000000000000000000000000000000003b`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L101C1-L113C5) <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000664f90d500000000` <br/>
  **Meaning**: Sets the `respectedGameType` and `respectedGameTypeUpdatedAt` slot (0x3b is equivalent to 59).
The `respectedGameType` is 32-bits wide at offset 0 which should be set to 0 (i.e. [`CANNON`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28)).
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

### Safe Contract State Changes

The only other state changes should be restricted to one of the following addresses:

- L1 2/2 ProxyAdmin Owner Safe: `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`
  - The nonce (slot 0x5) should be increased from 2 to 3.
  - Another key is set from 0 to 1 reflecting an entry in the `approvedHashes` mapping.
- Security Council L1 Safe: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
  - The nonce (slot 0x5) should be increased from 2 to 3.
- Foundation L1 Upgrades Safe: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
  - The nonce (slot 0x5) should be increased from 2 to 3.
