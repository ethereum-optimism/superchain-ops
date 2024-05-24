# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (The 2/2 `ProxyAdmin` Owner)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x1Eb2fFc903729a0F03966B917003800b145F56E2)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

### `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (Council Safe) or `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (Foundation Safe)

Links:
- [Etherscan (Council Safe)](https://sepolia.etherscan.io/address/0xf64bc17485f0B4Ea5F06A96514182FC4cB561977). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#mitigations).
- [Etherscan (Foundation Safe)](https://sepolia.etherscan.io/address/0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#mitigations).

The Safe you are signing for will have the following overrides which will set the [Multicall](https://sepolia.etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11#code) contract as the sole owner of the signing safe. This allows simulating both the approve hash and the final tx in a single Tenderly tx.

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

### `0x16fc5058f25648194471939df75cf27a2fdc48bc` (`OptimismPortal`)

- `prevBoughtGas`: value changes (depends on execution) 
- `prevBlockNum`: value increases (depends on execution) 


### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (The 2/2 `ProxyAdmin` Owner)

State Changes:

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000005 <br/>
  **Before:** 0x0000000000000000000000000000000000000000000000000000000000000005 <br/>
  **After:** 0x0000000000000000000000000000000000000000000000000000000000000006 <br/>
The nonce is increased from 5 to 6.

#### For the Council:

- **Key:** `0x3481a62ac310eecec9b2bcbdfc7f9759c1641b33ec9f302e19c8dc75aa3427bb` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Council Safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`
      - The safe hash to approve: `0x7e8055d58462ab08d75766766252966eda91b23097f8d96aca0547fe7aae078a`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8
        0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
        ```
        and
      ```shell
        $ cast index bytes32 0x7e8055d58462ab08d75766766252966eda91b23097f8d96aca0547fe7aae078a 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
        0x3481a62ac310eecec9b2bcbdfc7f9759c1641b33ec9f302e19c8dc75aa3427bb
        ```
      And so the output of the second command matches the key above.

#### For the Foundation:

- **Key:** `0x66833911cd4988ff9068991368a392dfd91753075a1080eee9ac5b6bf6a4815b` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Foundation Safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`
      - The safe hash to approve: `0x7e8055d58462ab08d75766766252966eda91b23097f8d96aca0547fe7aae078a`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8
        0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
      ```
      and
      ```shell
        $ cast index bytes32 0x7e8055d58462ab08d75766766252966eda91b23097f8d96aca0547fe7aae078a 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
        0x66833911cd4988ff9068991368a392dfd91753075a1080eee9ac5b6bf6a4815b
      ```
      And so the output of the second command matches the key above.


The only other state change are two nonce increments:

- One on the Council or Foundation safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` for Foundation and `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` for Council). If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One on the owner on the safe that sent the transaction.

## Additional Checks To Perform

### Cross-chain upgrade

This is a two step process, we want to:
1. Validate L1 execution completed successfully
2. Validate L2 execution completed successfully

### L1 Execution validation

On the Tenderly simulation, go to the 'Events' tab and look for the `TransactionDeposited` event.

Decode the `opaqueData` property using chisel from Foundry: 

Open chisel and declare the function that'll decode the `opaqueData`:
```solidity
    function decode(bytes calldata opaqueData) public pure
        returns (
            uint256 _msgValue,
            uint256 _value,
            uint64 _gasLimit,
            bool _isCreation,
            bytes memory _data
        )
    {
        uint256 offset = 0;

        _msgValue = uint256(bytes32(opaqueData[offset:offset + 32]));
        offset += 32;

        _value = uint256(bytes32(opaqueData[offset:offset + 32]));
        offset += 32;

        _gasLimit = uint64(bytes8(opaqueData[offset:offset + 8]));
        offset += 8;

        _isCreation = bytes1(opaqueData[offset]) != 0x00;

        offset += 1;
        _data = opaqueData[offset:];

        return (_msgValue, _value, _gasLimit, _isCreation, _data);
    }
```
Decode the `opaqueData`.
```solidity
(uint256 _msgValue, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data) = this.decode(hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d400099a88ec40000000000000000000000004200000000000000000000000000000000000014000000000000000000000000c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30014");
```
Check each value individually by typing the variable name into chisel and hitting enter:
1. `_msgValue`: 0
2. `_value`: 0
3. `_gasLimit`: 200000
4. `_isCreation`: false
5. `_data`: `0x99a88ec40000000000000000000000004200000000000000000000000000000000000014000000000000000000000000c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30014`

Decode the `_data` bytes, this is the calldata for invoking the `upgrade` function on the L2 ProxyAdmin: 
```bash
cast calldata-decode "upgrade(address,address)" yourDataHereWith0xPrefix
```
Notice 2 addresses are output: 
```solidity
0x4200000000000000000000000000000000000014
0xC0D3c0d3c0d3c0d3c0D3C0d3C0D3C0D3c0d30014
```
The first is the [`L2ERC721Bridge`](https://github.com/ethereum-optimism/optimism/blob/4c3f63de0995e4783a4ecce60ac48856954ce0c5/op-service/predeploys/addresses.go#L21) predeploy. 
The second is the current implementation address of this contract which you can check [onchain](https://sepolia-optimism.etherscan.io/address/0x4200000000000000000000000000000000000014#readProxyContract). Remember this is a no-op upgrade, so we don't actually want to change the implementation code.

### L2 Execution validation

Since Tenderly doesn't simulate the entire cross-chain interaction, this validation can only be confirmed after execution. If the [*L1 Execution validation*](#l1-execution-validation) section was followed thoroughly and there are no issues with the L2 chain deposit transaction flow, then it should work as expected. However, for absolute confirmation, perform the following post-execution checks.

**Post-Execution Checks**

1. Find the L2 deposit transaction by identifying the alias of the L1 ProxyAdmin owner safe. You can use [chisel](https://book.getfoundry.sh/chisel/) to verify the aliasing result by invoking the `applyL1ToL2Alias` function. Refer to this code here: [`applyL1ToL2Alias`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/vendor/AddressAliasHelper.sol#L28).
    ```bash
    applyL1ToL2Alias(0x1Eb2fFc903729a0F03966B917003800b145F56E2) = 0x2FC3ffc903729a0f03966b917003800B145F67F3
    ```
2. The transaction you're looking for should be the most recent transaction sent from [`0x2FC3ffc903729a0f03966b917003800B145F67F3`](https://sepolia-optimism.etherscan.io/address/0x2FC3ffc903729a0f03966b917003800B145F67F3) on L2. If it's not, then it should be a _recent_ transaction from [`0x2FC3ffc903729a0f03966b917003800B145F67F3`](https://sepolia-optimism.etherscan.io/address/0x2FC3ffc903729a0f03966b917003800B145F67F3) that was interacting with the L1 ProxyAdmin Owner [`0x4200000000000000000000000000000000000018`](https://sepolia-optimism.etherscan.io/address/0x4200000000000000000000000000000000000018).
3. Once you've found the correct transaction, verify that the expected log event was emit, similar to this testnet [log event](https://sepolia-optimism.etherscan.io/tx/0x2c42b8fad843f49abde106afe888f94be5bef8dabf60238fc0a4893aef0ff9a9#eventlog). The implementation address in our case should be [`0xC0D3c0d3c0d3c0d3c0D3C0d3C0D3C0D3c0d30014`](https://sepolia-optimism.etherscan.io/address/0xC0D3c0d3c0d3c0d3c0D3C0d3C0D3C0D3c0d30014).