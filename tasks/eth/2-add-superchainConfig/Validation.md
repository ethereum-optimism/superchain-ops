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

There should also be a single 'State Override' in the Foundation Safe contract
(`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`) to enable the simulation by reducing the threshold to
1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

**Notes:**
- The value `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` occurs
  multiple times below, and corresponds to the storage key of the implementation address as defined
  in
  [Proxy.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/src/universal/Proxy.sol#L104)
  and
  [Constants.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/src/libraries/Constants.sol#L26-L27).
- In order to minimize the validation effort, **"Before"** values are only included below when they are non-zero prior to the upgrade.

### `0x229047fed2591dbec1ef1118d64f7af3db9eb290` (`SystemConfigProxy`)

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Value:** `0x00000000000000000000000033a032ec93ec0c492ec4bf0b30d5f51986e5a314` <br/>
  **Meaning:** Implementation address is set to the new [`SystemConfig`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/cmd/op-upgrade-extended-pause/main.go#L43-L46).

### `0x25ace71c97b33cc4729cf772ae268934f7ab5fa1` (`L1CrossDomainMessengerProxy`)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x000000000000000000000001de1fcfb0851916ca5101820a69b13a4e276bd81f` <br/>
  **After:**  `0x0000000000000000000000010000000000000000000000000000000000000000` <br/>
  **Meaning:** The "Before" value was `abi.encodePacked(true, address(libAddressManager)`. The boolean
    value corresponds to the initialized state, which must be true. The address being deleted is
    the `AddressManager`, it was used in the legacy L1xDM to look up the address of the CTC. It is
    safe to delete because it is no longer in use, as shown by the presence of a [spacer](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/src/universal/CrossDomainMessenger.sol#L19)
    in the current implementation.

- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000fb` <br/>
  **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` <br/>
  **Meaning:** Sets the `SuperchainConfigProxy` address at slot `0xfb` (251). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L122-L127).


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

### `0xde1fcfb0851916ca5101820a69b13a4e276bd81f` (`AddressManager`)

- **Key:** `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e` <br/>
  **Before:** `0x0000000000000000000000002150bc3c64cbfddbac9815ef615d6ab8671bfe43` <br/>
  **After:** `0x000000000000000000000000a95b24af19f8907390ed15f8348a1a5e6ccbc5c6` <br/>
  **Meaning:** The name `OVM_L1CrossDomainMessenger` is set to the address of the new
  [`L1CrossDomainMessenger`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.2.0-rc.1/op-chain-ops/cmd/op-upgrade-extended-pause/main.go).
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
