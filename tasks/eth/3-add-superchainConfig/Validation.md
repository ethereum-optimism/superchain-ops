# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

Please ensure that the following changes (and none others) are made to each contract in the system.
Validation of the bytecode deployed at the implementation addresses is based on the presence of
those addresses at the tagged commit in the Optimism monorepo as linked below.

## Pre-upgrade deployed code

The `SuperchainConfigProxy` has already been deployed and initialized. It's address
`0x95703e0982140D16f8ebA6d158FccEde42f04a4C` appears in the state diff below in the contracts which
will begin querying it for the paused status.

- **Address Validation:** the address is
  [listed](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/upgrades/l1.go#L34)
   in the tooling used to generate
  the upgrade transaction bundle, at the governance approved tagged commit in the Optimism repo.

## State Overrides

The following state overrides should be seen:

### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (The 2 of 2 `ProxyAdmin` owner Safe)

Enables the simulation by reducing the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Council Safe) or `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Safe)

The Safe you are signing for will have the following overrides which will set the [Multicall](https://etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11#code) contract as the sole owner of the signing safe. This allows simulating both the approve hash and the final tx in a single Tenderly tx.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001
  **Meaning:** The number of owners is set to 1.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001
  **Meaning:** The threshold is set to 1.

The following two overrides are modifications to the [`owners` mapping](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L15). For the purpose of calculating the storage, note that this mapping is in slot `2`.
This mapping implements a linked list for iterating through the list of owners. Since we'll only have one owner (Multicall), and the `0x01` address is used as the first and last entry in the linked list, we will see the following overrides:
- `owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11`
- `owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1`

And we do indeed see these entries:

- **Key:** 0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001
  **Meaning:** This is `owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1`, so the key can be
    derived from `cast index address 0xca11bde05977b3631167028862be2a173976ca11 2`.


- **Key:** 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 <br/>
  **Value:** 0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11
  **Meaning:** This is `owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001`.

## State Changes

**Notes:**
- The value `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` occurs
  multiple times below, and corresponds to the storage key of the implementation address as defined
  in
  [Proxy.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/src/universal/Proxy.sol#L104)
  and
  [Constants.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/src/libraries/Constants.sol#L26-L27).
- In order to minimize the validation effort, **"Before"** values are only included below when they are not implementation addresses being swapped out, and when they are non-zero prior to the upgrade.

### `0x229047fed2591dbec1ef1118d64f7af3db9eb290` (`SystemConfigProxy`)

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Value:** `0x00000000000000000000000033a032ec93ec0c492ec4bf0b30d5f51986e5a314` <br/>
  **Meaning:** Implementation address is set to the new [`SystemConfig`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/cmd/op-upgrade-extended-pause/main.go#L43-L46).

### `0x25ace71c97b33cc4729cf772ae268934f7ab5fa1` (`L1CrossDomainMessengerProxy`)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x000000000000000000000001de1fcfb0851916ca5101820a69b13a4e276bd81f` <br/>
  **After:**  `0x0000000000000000000000010000000000000000000000000000000000000000` <br/>
  **Meaning:** The "Before" value was `abi.encodePacked(true, address(libAddressManager)`.
    - The boolean value corresponds to the initialized state, which must be true.
    - The address being deleted is the `AddressManager`, it was used in the legacy L1xDM to look up the address of the CTC. It is
    safe to delete because it is no longer in use, as shown by the presence of a [spacer](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol#L19)
    in the current implementation.

- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000fb` <br/>
  **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` <br/>
  **Meaning:** Sets the `SuperchainConfigProxy` address at slot `0xfb` (251). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L122-L127).

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (The 2 of 2 `ProxyAdmin` owner Safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The Safe nonce is updated.

#### For the Council:

- **Key:** `0xc17968c40bf9fa0af0c9c957e0f95fb7d057c959f119d672b696ef249c039704` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Council Safe: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
      - The safe hash to approve: `0x782cc13743013d9b1b0854b914bba5ebde49971466bf982c98d4ba911eb0d42d`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 8
        0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
        ```
        and
      ```shell
        $ cast index bytes32 0x782cc13743013d9b1b0854b914bba5ebde49971466bf982c98d4ba911eb0d42d 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d88
        0xc17968c40bf9fa0af0c9c957e0f95fb7d057c959f119d672b696ef249c039704
        ```
      And so the output of the second command matches the key above.

#### For the Foundation:

- **Key:** `0x66dfee7d20e8ae2c45828a6a3c2c79c377eccb8b4cea869195a802469fe70584` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Council Safe: `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`
      - The safe hash to approve: `0x782cc13743013d9b1b0854b914bba5ebde49971466bf982c98d4ba911eb0d42d`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 8
        0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
      ```
      and
      ```shell
        $ cast index bytes32 0x782cc13743013d9b1b0854b914bba5ebde49971466bf982c98d4ba911eb0d42d 0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
        0x66dfee7d20e8ae2c45828a6a3c2c79c377eccb8b4cea869195a802469fe70584
      ```
      And so the output of the second command matches the key above.

### `0x5a7749f83b81b301cab5f48eb8516b986daef23d` (`L1ERC721BridgeProxy`)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000032` <br/>
  **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` <br/>
  **Meaning:** Sets the `SuperchainConfigProxy` address at slot `0x32` (50). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L31-L35).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **After:** `0x000000000000000000000000c599fa757c2bcaa5ae3753ab129237f38c10da0b` <br/>
  **Meaning:** The implementation address is set to the [`L1ERC721Bridge`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/cmd/op-upgrade-extended-pause/main.go#L31-L33).

### `0x75505a97bd334e7bd3c476893285569c4136fa0f` (`OptimismMintableERC20FactoryProxy`)

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **After:** `0x00000000000000000000000074e273220fa1cb62fd756fe6cbda8bbb89404ded` <br/>
  **Meaning:** Implementation address is set to the new [`OptimismMintableERC20Factory`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/cmd/op-upgrade-extended-pause/main.go#L51-L53).

### Foundation Only: `0x847b5c174615b1b7fdf770882256e2d3e95b9d92` (Foundation Safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The nonce is increased by one.

### `0x99c9fc46f92e8a1c0dec1b1747d010903e884be1` (`L1StandardBridgeProxy`)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x00000000000000000000000025ace71c97b33cc4729cf772ae268934f7ab5fa1` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. <br/>
  **Additional Note:** The "Before" value which is being deleted is the address of the
  `L1CrossDomainMessengerProxy`. This storage entry was an artifact of the pre-bedrock system. The
  bedrock upgrade moved this value from storage into the contract's bytecode as an [`immutable` value](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/src/universal/StandardBridge.sol#L26).
  It is no longer in use and is safe to delete.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000032` <br/>
  **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` <br/>
  **Meaning:** Sets the `SuperchainConfigProxy` address at slot `0x32` (50). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L31-L35).


- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **After:** `0x000000000000000000000000566511a1a09561e2896f8c0fd77e8544e59bfdb0` <br/>
  **Meaning:** Implementation address is set to the new [`L1StandardBridge`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/cmd/op-upgrade-extended-pause/main.go#L51-L53).

### `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a` (`SafeProxy`)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000057` <br/>
  **Meaning:** The Safe nonce is updated.<br/>
  **Additional Note:** This number may be slightly different if other transactions have recently
  been executed. The important thing is that it should increment by 1.

### `0xbeb5fc579115071764c7423a4f12edde41f106ed` (`OptimismPortalProxy`)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000035` <br/>
  **After:** `0x000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c00` <br/>
  **Meaning:** Sets the `SuperchainConfigProxy` address at slot `0x32` (50). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L59-L63).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **After:** `0x000000000000000000000000ababe63514ddd6277356f8cc3d6518aa8bdeb4de` <br/>
  **Meaning:** Implementation address is set to the new [`OptimismPortal`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/cmd/op-upgrade-extended-pause/main.go#L39-L42).

### Council Only: `0xc2819dc788505aac350142a7a707bf9d03e3bd03` (Council Safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The nonce is increased by one.

### `0xde1fcfb0851916ca5101820a69b13a4e276bd81f` (`AddressManager`)

- **Key:** `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e` <br/>
  **Before:** `0x0000000000000000000000002150bc3c64cbfddbac9815ef615d6ab8671bfe43` <br/>
  **After:** `0x000000000000000000000000a95b24af19f8907390ed15f8348a1a5e6ccbc5c6` <br/>
  **Meaning:** The name `OVM_L1CrossDomainMessenger` is set to the address of the new
  [`L1CrossDomainMessenger`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/cmd/op-upgrade-extended-pause/main.go#L27-L30).
  The correctness of this slot can be validated by verifying that the
  **Before** address matches both of the following cast calls (please consider changing out the rpc
  url):
  1. what is returned by calling `AddressManager.getAddress()`:
   ```
   cast call 0xde1fcfb0851916ca5101820a69b13a4e276bd81f 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url https://ethereum.publicnode.com
   ```
  2. what is currently stored at the key:
   ```
   cast st 0xde1fcfb0851916ca5101820a69b13a4e276bd81f 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url https://ethereum.publicnode.com
   ```

### `0xdfe97868233d1aa22e815a266982f2cf17685a27` (`L2OutputOracleProxy`)

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **After:** `0x000000000000000000000000db5d932af15d00f879cabebf008cadaaaa691e06` <br/>
  **Meaning:** Implementation address is set to the new [`L2OutputOracle`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/cmd/op-upgrade-extended-pause/main.go#L47-L50).
