# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:
- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (The 2 of 2 `ProxyAdmin` owner Safe)

Links:
- [Etherscan](https://etherscan.io/address/0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A)

Enables the simulation by reducing the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Council Safe) or `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Safe)

Links:
- [Etherscan (Council Safe)](https://etherscan.io/address/0xc2819DC788505Aac350142A7A707BF9D03E3Bd03). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#mitigations).
- [Etherscan (Foundation Safe)](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#mitigations).

The Safe you are signing for will have the following overrides which will set the [Multicall](https://etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11#code) contract as the sole owner of the signing safe. This allows simulating both the approve hash and the final tx in a single Tenderly tx.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The number of owners is set to 1.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The threshold is set to 1.

The following two overrides are modifications to the [`owners` mapping](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L15). For the purpose of calculating the storage, note that this mapping is in slot `2`.
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
  in [Proxy.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/universal/Proxy.sol#L104) and [Constants.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/libraries/Constants.sol#L26-L27). This is useful for EIP-1967 proxies.
- Check the provided links to ensure that the correct contract is described at the correct address. The superchain registry is the source of truth for contract addresses and etherscan is supplementary.

### `0x229047fed2591dbec1ef1118d64f7af3db9eb290` (`SystemConfigProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x229047fed2591dbec1ef1118d64f7af3db9eb290)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L10)

State Changes:

Please ensure that each link to the `superchain-registry` correctly corresponds to OP Mainnet as the superchain registry contains data for
different chains. The `superchain-registry` is considered the source of truth for contract addresses across the superchain. To ensure
that the address actually matches the correct implementation, an Etherscan link is also provided for each.

[system-config-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/implementations/networks/mainnet.yaml#L14
[system-config-etherscan]: https://etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1
[l1-xdm-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L3
[l1-xdm-proxy-etherscan]: https://etherscan.io/address/0x25ace71c97b33cc4729cf772ae268934f7ab5fa1
[l1-erc721-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L4
[l1-erc721-etherscan]: https://etherscan.io/address/0x5a7749f83b81b301cab5f48eb8516b986daef23d
[portal-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L8
[portal-etherscan]: https://etherscan.io/address/0xbeb5fc579115071764c7423a4f12edde41f106ed
[batch-inbox-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/configs/mainnet/op.yaml#L8
[batch-inbox-etherscan]: https://etherscan.io/address/0xff00000000000000000000000000000000000010
[l1-standard-bridge-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L5
[l1-standard-bridge-etherscan]: https://etherscan.io/address/0x99c9fc46f92e8a1c0dec1b1747d010903e884be1
[factory-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L7
[factory-etherscan]: https://etherscan.io/address/0x75505a97bd334e7bd3c476893285569c4136fa0f
[output-oracle-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L6
[output-oracle-etherscan]: https://etherscan.io/address/0xdfe97868233d1aa22e815a266982f2cf17685a27

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x00000000000000000000000033a032ec93ec0c492ec4bf0b30d5f51986e5a314` <br/>
  **After:** `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1` <br/>
  **Meaning:** Implementation address is set to the new `SystemConfig` per the [Superchain Registry][system-config-registry] and [Etherscan][system-config-etherscan].

- **Key:** `0x383f291819e6d54073bc9a648251d97421076bdd101933c0c022219ce9580636` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000025ace71c97b33cc4729cf772ae268934f7ab5fa1` <br/>
  **Meaning:** Sets `l1CrossDomainMessenger` address at slot per the [Superchain Registry][l1-xdm-etherscan]. This should be a proxy address per [Etherscan][l1-xdm-proxy-etherscan]. Verification of the key can be done by ensuring the result of the [L1_CROSS_DOMAIN_MESSENGER_SLOT](https://etherscan.io/address/0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1#readContract#F2) getter on the implementation contract matches the key.

- **Key:** `0x46adcbebc6be8ce551740c29c47c8798210f23f7f4086c41752944352568d5a7` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000005a7749f83b81b301cab5f48eb8516b986daef23d` <br/>
  **Meaning:** Sets `l1ERC721Bridge` address at slot per the [Superchain Registry][l1-erc721-registry]. This should be a proxy address per [Etherscan][l1-erc721-etherscan]. Verification of the key can be done by ensuring the result of the [L1_ERC_721_BRIDGE_SLOT](https://etherscan.io/address/0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1#readContract#F3) getter on the implementation contract matches the key.

- **Key:** `0x4b6c74f9e688cb39801f2112c14a8c57232a3fc5202e1444126d4bce86eb19ac` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000beb5fc579115071764c7423a4f12edde41f106ed` <br/>
  **Meaning:** Sets `optimismPortal` at slot per the [Superchain Registry][portal-registry]. This should be a proxy address per [Etherscan][portal-etherscan]. Verification of the key can be done by ensuring the result of the [OPTIMISM_PORTAL_SLOT](https://etherscan.io/address/0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1#readContract#F7) getter on the implementation contract matches the key.

- **Key:** `0x71ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000ff00000000000000000000000000000000000010` <br/>
  **Meaning:** Sets `batchInbox` at slot per the [Superchain Registry][batch-inbox-registry]. This should be an address with no code per [Etherscan][batch-inbox-etherscan]. Verification of the key can be done by ensuring the result of the [BATCH_INBOX_SLOT](https://etherscan.io/address/0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1#readContract#F1) getter on the implementation contract matches the key.

- **Key:** `0x9904ba90dde5696cda05c9e0dab5cbaa0fea005ace4d11218a02ac668dad6376` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000099c9fc46f92e8a1c0dec1b1747d010903e884be1` <br/>
  **Meaning:** Sets `l1StandardBridge` at slot per the [Superchain Registry][l1-standard-bridge-registry]. This should be a proxy address per [Etherscan][l1-standard-bridge-etherscan]. Verification of the key can be done by ensuring the result of the [L1_STANDARD_BRIDGE_SLOT](https://etherscan.io/address/0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1#readContract#F4) getter on the implementation contract matches the key.

- **Key:** `0xa04c5bb938ca6fc46d95553abf0a76345ce3e722a30bf4f74928b8e7d852320c` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000075505a97bd334e7bd3c476893285569c4136fa0f` <br/>
  **Meaning:** Sets `optimismMintableERC20Factory` at slot per the [Superchain Registry][factory-registry]. This should be a proxy address per [Etherscan][factory-etherscan]. Verification of the key can be done by ensuring the result of the [OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT](https://etherscan.io/address/0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1#readContract#F6) getter on the implementation contract matches the key.

- **Key:** `0xa11ee3ab75b40e88a0105e935d17cd36c8faee0138320d776c411291bdbbb19f` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000000000000000000000000000000000000109d86c` <br/>
  **Meaning:** Sets `startBlock` at slot to 17422444. This should be the blocknumber at which the `SystemConfig` proxy was initialized for the first time. [Etherscan](https://etherscan.io/advanced-filter?eladd=0x229047fed2591dbec1eF1118d64F7aF3dB9EB290&eltpc=0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498) filter shows the transactions that initialized the proxy, the oldest one should be checked to ensure its blocknumber matches what is here. Verification of the key can be done by ensuring the result of the [START_BLOCK_SLOT](https://etherscan.io/address/0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1#readContract#F8) getter on the implementation contract matches the key.

- **Key:** `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000dfe97868233d1aa22e815a266982f2cf17685a27` <br/>
  **Meaning:** Sets `l2OutputOracle` at slot per the [Superchain Registry][output-oracle-registry]. This should be a proxy per [Etherscan][output-oracle-etherscan]. Verification of the key can be done by ensuring the result of the [L2_OUTPUT_ORACLE_SLOT](https://etherscan.io/address/0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1#readContract#F5) getter on the implementation contract matches the key.

### `0x25ace71c97b33cc4729cf772ae268934f7ab5fa1` (`L1CrossDomainMessengerProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x25ace71c97b33cc4729cf772ae268934f7ab5fa1)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L3)

State Changes:
- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000cf` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x0000000000000000000000004200000000000000000000000000000000000007` <br/>
  **Meaning:** Sets `otherMessenger` at slot `0xcf` (207). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L115-L119). The `otherMessenger` address should be the the [L2CrossDomainMessenger](https://optimistic.etherscan.io/address/0x4200000000000000000000000000000000000007).

- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000fc` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x000000000000000000000000beb5fc579115071764c7423a4f12edde41f106ed` <br/>
  **Meaning:** Sets `OptimismPortal` at slot `0xfc` (252). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L136-L140). The `OptimismPortal` address can be found [here](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L8).

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (The 2 of 2 `ProxyAdmin` owner Safe)

Links:
- [Etherscan](https://etherscan.io/address/0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L11)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning:** The Safe nonce is updated.

#### For the Council:

- **Key:** `0x4c86e529f4c6c8a1297468d37da3ed07c5e661e07722d010373a4a8ca61822d6` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Council Safe: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
      - The safe hash to approve: `0xa262a5d8e4b2218c9c47c045028d5fd49f9191565837f3afd8e4ae118a60e2b3`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 8
        0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
        ```
        and
      ```shell
        $ cast index bytes32 0xa262a5d8e4b2218c9c47c045028d5fd49f9191565837f3afd8e4ae118a60e2b3 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
        0x4c86e529f4c6c8a1297468d37da3ed07c5e661e07722d010373a4a8ca61822d6
        ```
      And so the output of the second command matches the key above.

#### For the Foundation:

- **Key:** `0x5a2e529e7b2feaedb77a6a1784f400f0d0de9ed9f2c41a0e9adaba3d4fce28a6` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Foundation Safe: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
      - The safe hash to approve: `0xa262a5d8e4b2218c9c47c045028d5fd49f9191565837f3afd8e4ae118a60e2b3`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 8
        0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
      ```
      and
      ```shell
        $ cast index bytes32 0xa262a5d8e4b2218c9c47c045028d5fd49f9191565837f3afd8e4ae118a60e2b3 0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
        0x5a2e529e7b2feaedb77a6a1784f400f0d0de9ed9f2c41a0e9adaba3d4fce28a6
      ```
      And so the output of the second command matches the key above.

### `0x5a7749f83b81b301cab5f48eb8516b986daef23d` (`L1ERC721BridgeProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x5a7749f83b81b301cab5f48eb8516b986daef23d)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L4)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000025ace71c97b33cc4729cf772ae268934f7ab5fa1` <br/>
    **Meaning:** Sets `messenger` at slot `0x01` (1). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L24-L28). The address of the [L1CrossDomainMessengerProxy](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L3) should be in the slot with left padding to fill the storage slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000004200000000000000000000000000000000000014` <br/>
  **Meaning:** Sets `otherBridge` at slot `0x02` (2). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L31-L35). This should correspond to the L2ERC721Bridge address as seen on Optimistic Etherscan [here](https://optimistic.etherscan.io/address/0x4200000000000000000000000000000000000014#code), and it's [implementation](https://optimistic.etherscan.io/address/0xc0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30014#code) is named L2ERC721Bridge. The slot has left padding of zero bytes to fill the storage slot.

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000c599fa757c2bcaa5ae3753ab129237f38c10da0b` <br/>
  **After:** `0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d` <br/>
  **Meaning:** The implementation address is set to the new `L1ERC721Bridge`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/implementations/networks/mainnet.yaml#L4).

### `0x75505a97bd334e7bd3c476893285569c4136fa0f` (`OptimismMintableERC20FactoryProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x75505a97bd334e7bd3c476893285569c4136fa0f)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L7)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismMintableERC20Factory.json](https://github.com/ethereum-optimism/optimism/blob/e6ef3a900c42c8722e72c2e2314027f85d12ced5/packages/contracts-bedrock/snapshots/storageLayout/OptimismMintableERC20Factory.json#L2-L15).
   This state diff will only appear in contracts that were previously not initializable. Other contracts are reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000099c9fc46f92e8a1c0dec1b1747d010903e884be1` <br/>
  **Meaning:** Sets `bridge` at slot `0x01` (1). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismMintableERC20Factory.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismMintableERC20Factory.json#L24-L28). The address of the `L1StandardBridge` should be the value set in the slot, left padded with zero bytes to fill the slot. The address of the [L1StandardBridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L5) can be found in the Superchain Registry.

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x00000000000000000000000074e273220fa1cb62fd756fe6cbda8bbb89404ded` <br/>
  **After:** `0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846` <br/>
  **Meaning:** Implementation address is set to the new `OptimismMintableERC20Factory` implementation. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/implementations/networks/mainnet.yaml#L10).

### Foundation Only: `0x847b5c174615b1b7fdf770882256e2d3e95b9d92` (Foundation Safe)

Links:
- [Etherscan](https://etherscan.io/address/0x847b5c174615b1b7fdf770882256e2d3e95b9d92)
- [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#mitigations)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning:** The nonce is increased by one.

### `0x99c9fc46f92e8a1c0dec1b1747d010903e884be1` (`L1StandardBridgeProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x99c9fc46f92e8a1c0dec1b1747d010903e884be1)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L5)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000025ace71c97b33cc4729cf772ae268934f7ab5fa1` <br/>
  **Meaning:** Sets `messenger` at slot `0x03` (3). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L38-L42). The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L3).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000004200000000000000000000000000000000000010` <br/>
  **Meaning:** Sets `otherBridge` at slot `0x04` (4). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L45-L49). This should correspond to the L2StandardBridge address as seen on Optimistic Etherscan [here](https://optimistic.etherscan.io/address/0x4200000000000000000000000000000000000010#code), and it's [implementation](https://optimistic.etherscan.io/address/0xc0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30010#code) is named L2StandardBridge. The slot has left padding of zero bytes to fill the storage slot.

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000566511a1a09561e2896f8c0fd77e8544e59bfdb0` <br/>
  **After:** `0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff` <br/>
  **Meaning:** Implementation address is set to the new `L1StandardBridge`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/implementations/networks/mainnet.yaml#L6).

### `0xbeb5fc579115071764c7423a4f12edde41f106ed` (`OptimismPortalProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0xbeb5fc579115071764c7423a4f12edde41f106ed)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L8)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000036` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After:** `0x000000000000000000000000dfe97868233d1aa22e815a266982f2cf17685a27` <br/>
  **Meaning:** Sets `l2Oracle` at slot `0x36` (54). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L66-L70). The `L2OutputOracleProxy` addres can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L6).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000037` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After:** `0x000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290` <br/>
  **Meaning:** Sets `systemConfig` at slot `0x37` (55). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L73-L77). The `SystemConfigProxy` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L10).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000ababe63514ddd6277356f8cc3d6518aa8bdeb4de`
  **After:** `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589` <br/>
  **Meaning:** Implementation address is set to the new `OptimismPortal`. The implementation address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/implementations/networks/mainnet.yaml#L12).

### Council Only: `0xc2819dc788505aac350142a7a707bf9d03e3bd03` (Council Safe)

Links:
- [Etherscan](https://etherscan.io/address/0xc2819dc788505aac350142a7a707bf9d03e3bd03)
- [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#mitigations)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning:** The nonce is increased by one.

### `0xde1fcfb0851916ca5101820a69b13a4e276bd81f` (`AddressManager`)

Links:
- [Etherscan](https://etherscan.io/address/0xde1fcfb0851916ca5101820a69b13a4e276bd81f)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L2)

State Changes:
- **Key:** `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e` <br/>
  **Before:** `0x000000000000000000000000a95b24af19f8907390ed15f8348a1a5e6ccbc5c6` <br/>
  **After:** `0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65` <br/>
  **Meaning:** The name `OVM_L1CrossDomainMessenger` is set to the address of the new `L1CrossDomainMessenger` [implementation](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/implementations/networks/mainnet.yaml#L2). This key is complicated to compute, so instead we attest to correctness of the key by verifying that the "Before" value currently exists in that slot, as explained below.
  **Before** address matches both of the following cast calls (please consider changing out the rpc
  url):
  1. what is returned by calling `AddressManager.getAddress()`:
   ```
   cast call 0xde1fcfb0851916ca5101820a69b13a4e276bd81f 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url https://ethereum.publicnode.com
   ```
  2. what is currently stored at the key:
   ```
   cast storage 0xde1fcfb0851916ca5101820a69b13a4e276bd81f 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url https://ethereum.publicnode.com
   ```

### `0xdfe97868233d1aa22e815a266982f2cf17685a27` (`L2OutputOracleProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0xdfe97868233d1aa22e815a266982f2cf17685a27)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/extra/addresses/mainnet/op.json#L6)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000708` <br/>
  **Meaning:** Sets `submissionInterval` at slot `0x04` (4). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L38-L42). It should be [1800](https://github.com/ethereum-optimism/optimism/blob/8829be92c390535c665e2e6d41a835f69a6b9145/packages/contracts-bedrock/deploy-config/mainnet.json#L15). `0x708` in hexadecimal is `1800` in decimal.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning:** Sets `l2BlockTime` at slot `0x05` (5). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L45-L49). Units are in seconds, so the value should be [2](https://github.com/ethereum-optimism/optimism/blob/8829be92c390535c665e2e6d41a835f69a6b9145/packages/contracts-bedrock/deploy-config/mainnet.json#L7).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a` <br/>
  **Meaning:** Sets `challenger` at slot `0x06` (6). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L52-L56). This is an address that can be verified with the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#challenger), and is padded with zero bytes to fill the slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000473300df21d047806a082244b417f96b32f13a33` <br/>
  **Meaning:** Sets `proposer` at slot `0x07` (7). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L59-L63). This is an address that can be verified with the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#proposer), and is padded with zero bytes to fill the slot.
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000093a80` <br/>
  **Meaning:** Sets `finalizationPeriodSeconds` at slot `0x08` (8). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L66-L70). Units are in seconds, so the value should be [604,800](https://github.com/ethereum-optimism/optimism/blob/8829be92c390535c665e2e6d41a835f69a6b9145/packages/contracts-bedrock/deploy-config/mainnet.json#L20), and 0x93a80 in hexadecimal is 604800 in decimal.

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000db5d932af15d00f879cabebf008cadaaaa691e06` <br/>
  **After:** `0x000000000000000000000000f243bed163251380e78068d317ae10f26042b292` <br/>
  **Meaning:** Implementation address is set to the new `L2OutputOracle`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/52d3dbd1605dd43f419e838584abd0ec163d462b/superchain/implementations/networks/mainnet.yaml#L8).

The only other state change is a nonce increment of account `0x07dc0893cafbf810e3e72505041f2865726fd073` if simulating as the council, or a nonce increment of `0x42d27eea1ad6e22af6284f609847cb3cd56b9c64` if simulating as the foundation.
These addresses correspond to the first owner listed in the respective Safes.

