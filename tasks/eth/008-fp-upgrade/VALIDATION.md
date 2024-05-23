# VALIDATION

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x229047fed2591dbec1ef1118d64f7af3db9eb290` (`SystemConfigProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x229047fed2591dbec1eF1118d64F7aF3dB9EB290)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/94149a2651f0aadb982802c8909d60ecae67e050/superchain/extra/addresses/mainnet/op.json#L10)

State Changes:
- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1` <br/>
  **After:** `0x000000000000000000000000f56d96b2535b932656d3c04ebf51babff241d886` <br/>
  **Meaning:** This upgrades the SystemConfig implementation. The only state change is an update to the eip1967 proxy implementation slot.


### `0xbeb5fc579115071764c7423a4f12edde41f106ed` (`OptimismPortalProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0xbEb5Fc579115071764c7423A4f12eDde41f106Ed)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L8)

Upgrades the `OptimismPortal` to the `OptimismPortal2` implementation. This occurs in three steps:

1. Upgrade the `OptimismPortal` implementation to the `StorageSetter` contract.
1. Reset the first slot of the `OptimismPortalProxy` storage to allow initialization.
1. Reset the `l2Sender` storage slot in the proxy to allow the first initialization of the new OptimismPortal implementation.
1. Upgrade the `OptimismPortal` implementation to the `OptimismPortal2` contract and execute `initialize(address,address,address,uint32)`.

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000038` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa9` <br/>
  **Meaning**: Sets the `DisputeGameFactoryProxy` address in the proxy storage. Consult the [gov proposal](https://gov.optimism.io/t/final-protocol-upgrade-7-fault-proofs/8161) for the proxy addreess value.

- **Key:** `0x000000000000000000000000000000000000000000000000000000000000003b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000664f90d500000000` <br/>
  **Meaning**: Sets the `respectedGameType` and `respectedGameTypeUpdatedAt` slot. The `respectedGameType` is 32-bits wide at offset 0 which should be set to 0 (i.e. `CANNON`). The `respectedGameTypeUpdatedAt` is 64-bits wide and offset by `4` on that slot. It should be equivalent to the unix timestamp of the block the upgrade was executed.


- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before**: `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589` <br/>
  **After**: `0x000000000000000000000000e2f826324b2faf99e513d16d266c3f80ae87832b` <br/>
  **Meaning**: Sets the eip1967 proxy implementation slot to the `OptimismPortal2` implementation.
