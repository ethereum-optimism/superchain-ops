# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

An image of the state diff in Tenderly can be viewed [here](./images/state_diff.png).

## State Overrides

The following state override should be seen:

### `0x0fe884546476dDd290eC46318785046ef68a0BA9` (Gnosis Safe `ProxyAdmin` owner)

Links:
- [Sepolia Etherscan](https://sepolia.etherscan.io/address/0x0fe884546476ddd290ec46318785046ef68a0ba9)

Overrides:
- **Key:**   `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** Enables the simulation by setting the signature threshold to 1. The key can be validated by the location of the `threshold` variable in 
  the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14)

## State Changes

**Notes:**
- The value `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` occurs
  multiple times below, and corresponds to the storage key of the implementation address as defined
  in
  [Proxy.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/src/universal/Proxy.sol#L104)
  and
  [Constants.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/src/libraries/Constants.sol#L26-L27).

### `0xf272670eb55e895584501d564AfEB048bEd26194` (`SystemConfigProxy`)

Links:
- [Sepolia Etherscan](https://sepolia.etherscan.io/address/0xf272670eb55e895584501d564afeb048bed26194)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/a06cb07264c985c041c0c01af57463ea88da264c/superchain/configs/sepolia/base.yaml#L12)

State Changes:
- **Key:**    `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1` <br/>
  **After:**  `0x000000000000000000000000ccdd86d581e40fb5a1c77582247bc493b6c8b169` <br/>
  **Meaning:** This upgrades the `SystemConfig` implementation address. The new `SystemConfig` implementation address should be the same as the one used by [Optimism's SystemConfig](https://sepolia.etherscan.io/address/0x034edD2A225f7f429A63E0f1D2084B9E0A93b538):
  ```bash
  # should return the same address as the before value
  cast storage 0xf272670eb55e895584501d564AfEB048bEd26194 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url <rpc_url>

  # should return the same address as the after value
  cast storage 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url <rpc_url>
  ```

- **Key:**    `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x000000000000000000000000d6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1` <br/>
  **Meaning:** Sets the [DisputeGameFactory slot](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/src/L1/SystemConfig.sol#L76). You can verify the correctness of the storage slots with `chisel`. Just start it up and enter the slot definitions as found in the contract source code.
  ```
  ➜ bytes32(uint256(keccak256("systemconfig.disputegamefactory")) - 1)
  Type: bytes32
  └ Data: 0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906
  ```

- **Key:**    `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815` <br/>
  **Before:** `0x00000000000000000000000084457ca9d0163fbc4bbfe4dfbb20ba46e48df254` <br/>
  **After:**  `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning:** Clears the old and unused [L2OutputOracle slot](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/L1/SystemConfig.sol#L63). You can verify the correctness of the storage slots with `chisel`. Just start it up and enter the slot definitions as found in the contract source code.
  ```
  ➜ bytes32(uint256(keccak256("systemconfig.l2outputoracle")) - 1)
  Type: bytes32
  └ Data: 0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815
  ```

### `0x49f53e41452C74589E85cA1677426Ba426459e85` (`OptimismPortalProxy`)

Links:
- [Sepolia Etherscan](https://sepolia.etherscan.io/address/0x49f53e41452c74589e85ca1677426ba426459e85)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/a06cb07264c985c041c0c01af57463ea88da264c/superchain/extra/addresses/sepolia/base.json#L8)

State Changes:
- **Key:**    `0x0000000000000000000000000000000000000000000000000000000000000038` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x000000000000000000000000d6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1` <br/>
  **Meaning:**  Sets the `DisputeGameFactoryProxy` address in the proxy storage (0x38 is equivalent to 56). Note the `DisputeGameFactoryProxy` address should be the same address as the one set in the `SystemConfigProxy` state changes.

- **Key:**    `0x000000000000000000000000000000000000000000000000000000000000003b` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x0000000000000000000000000000000000000000000000006692e10f00000000` <br/>
  **Meaning:** Sets the `respectedGameType` and `respectedGameTypeUpdatedAt` slot (0x3b is equivalent to 59).
  The `respectedGameType` is 32-bits wide at offset 0 which should be set to 0 (i.e. [`CANNON`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0-rc.4/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28)).
  The `respectedGameTypeUpdatedAt` is 64-bits wide and offset by `4` on that slot. It should be equivalent to the unix timestamp of the block the upgrade was executed.
  You can extract the offset values from the slot using `chisel`:
  ```
  ➜ uint256 x = 0x0000000000000000000000000000000000000000000000006692e10f00000000
  ➜ uint64 respectedGameTypeUpdatedAt = uint64(x >> 32)
  ➜ respectedGameTypeUpdatedAt
  Type: uint64
  ├ Hex: 0x
  ├ Hex (full word): 0x6692e10f
  └ Decimal: 1720901903
  ➜ 
  ➜ uint32 respectedGameType = uint32(x & 0xFFFFFFFF)
  ➜ respectedGameType
  Type: uint32
  ├ Hex: 0x
  ├ Hex (full word): 0x0
  └ Decimal: 0
  ```

- **Key:**    `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589` <br/>
  **After:**  `0x00000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233` <br/>
  **Meaning:** This upgrades the `OptimismPortalProxy` implementation address to `OptimismPortal2`. The implementation address should be the same as the one used by [Optimism's OptimismPortalProxy](https://sepolia.etherscan.io/address/0x16Fc5058F25648194471939df75CF27A2fdC48BC):
  ```bash
  # should return the same address as the before value
  cast storage 0x49f53e41452C74589E85cA1677426Ba426459e85 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url <rpc_url>

  # should return the same address as the after value
  cast storage 0x16Fc5058F25648194471939df75CF27A2fdC48BC 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url <rpc_url>
  ```

### Safe Contract State Changes

The only other state changes should be restricted to one of the following addresses:

- L1 Gnosis Safe `ProxyAdmin` owner: `0x0fe884546476dDd290eC46318785046ef68a0BA9`
  - The nonce in slot 0x05 should be incremented from 2 to 3.
