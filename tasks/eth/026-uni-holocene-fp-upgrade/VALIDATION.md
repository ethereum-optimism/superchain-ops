# Validation

This document can be used to validate the state diff resulting from the execution of the FP upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Nested Safe State Overrides and Changes

This task is executed by the nested 3/3 `ProxyAdminOwner` Safe with Unichain (`0x6d5B183F538ABB8572F5cD17109c617b994D5833`).
Refer to the [generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)
for the expected state overrides and changes - except for two active nonce overrides for the foundation and security council, which are described below.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the simulation is
- Council simulation: `0x568b8aba0ab4ee2af4639a4fd31bba2c11adcebaec482afc2699d34c3b21f32b`
- Foundation simulation: `0xb4a9e4ff89a9d93c76d7d832cbc444bc908574ac3e65bb031236999af8e42b74`
- Chain Governor simulation: `0xf45c50f658f1c1156ebc02208b87c846b9f5c470124d1bd92ce765f4c696abb2`

calculated as explained in the nested validation doc:
```sh
SAFE_HASH=0x41f0e95f184f6402520b1628e6d1f8fe9153d45d5d4b66a3b768145563f90027 # "Nested hash:"
SAFE_ROLE=0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 # Council
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0x568b8aba0ab4ee2af4639a4fd31bba2c11adcebaec482afc2699d34c3b21f32b

SAFE_ROLE=0x847B5c174615B1B7fDF770882256e2D3E95b9D92 # Foundation
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0xb4a9e4ff89a9d93c76d7d832cbc444bc908574ac3e65bb031236999af8e42b74

SAFE_ROLE=0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC # Unichain
cast index bytes32 $SAFE_HASH $(cast index address $SAFE_ROLE 8)
# 0xf45c50f658f1c1156ebc02208b87c846b9f5c470124d1bd92ce765f4c696abb2
```

## Safe Nonce Overrides

### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation `GnosisSafeProxy`)

Only during Foundation simulation.

We're overriding the nonce to increment the current value `12` by `1` to account for task `ink-001`.
The simulation will also print out
```
Overriding nonce for safe 0x847B5c174615B1B7fDF770882256e2D3E95b9D92: 12 -> 13
```
And the state changes then show that this nonce is increased from 12 to 13 during the simulation.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005`<br/>
  **Value:** `0x000000000000000000000000000000000000000000000000000000000000000d` (`13`)<br/>
  **Meaning:** The Foundation Safe nonce is bumped from 12 to 13.

The other state overrides are explained in the generic nested Safe validation document referred to
above.

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council `GnosisSafeProxy`)

Only during Security Council simulation.

We're overriding the nonce to increment the current value `9` by `1` to account for task `ink-001`.
The simulation will also print out
```
Overriding nonce for safe 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03: 9 -> 10
```
And the state changes then show that this nonce is increased from 9 to 10 during the simulation.

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005`<br/>
  **Value:** `0x000000000000000000000000000000000000000000000000000000000000000a` (`10`)<br/>
  **Meaning:** The Council Safe nonce is bumped from 9 to 10.

The other state overrides are explained in the generic nested Safe validation document referred to
above.

## State Changes

### `0x2F12d621a16e2d3285929C9996f478508951dFe4` (`DisputeGameFactoryProxy`)

#### Two changes from `setImplementation`

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x00000000000000000000000008f0f8f4e792d21e16289db7a80759323c446f61` <br/>
  **Meaning**: Updates the CANNON game type implementation.
    You can verify which implementation is set using `cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
    Before this task has been executed, you will see that the returned address is `0x0000000000000000000000000000000000000000`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the CANNON implementation.
    The key can be verified with `cast index uint32 0 101` for game type 0 and [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.8.0-rc.4/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L38C1-L43C5).


- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000b2872ec9e7074d5838d9a27ae06c53dba8669e8d` <br/>
  **After**: `0x000000000000000000000000c457172937ffa9306099ec4f2317903254bf7223` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation.
    You can verify which implementation is set using `cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 1`, where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).
    Before this task has been executed, you will see that the returned address is `0xB2872eC9e7074D5838D9a27Ae06c53DbA8669E8D`, matching the "Before" value of this slot, demonstrating this slot is storing the address of the PERMISSIONED_CANNON implementation.
    The key can be verified with `cast index uint32 1 101` for game type 1 and [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.8.0-rc.4/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L38C1-L43C5).

#### Two changes from `setInitBond`

You can confirm that `0.08 ETH` are indeed `0x11c37937e080000` with `cast to-unit 0x11c37937e080000 ether`.

- **Key**: `0x6f48904484b35701cf1f41ad9068b394adf7e2f8a59d2309a04d10a155eaa72b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000011c37937e080000` <br/>
  **Meaning**: Sets the initial bond size for game type 0 to 0.08 ETH.
    Verify that the slot is correct using `cast index uint 0 102`. Where `0` is the game type and 102 is the [storage slot](https://github.com/ethereum-optimism/optimism/blob/33f06d2d5e4034125df02264a5ffe84571bd0359/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L48).

- **Key**: `0xe34b8b74e1cdcaa1b90aa77af7dd89e496ad9a4ae4a4d4759712101c7da2dce6` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000011c37937e080000` <br/>
  **Meaning**: Sets the initial bond size for game type 1 to 0.08 ETH.
    Verify that the slot is correct using `cast index uint 1 102`. Where `1` is the game type and 102 is the [storage slot](https://github.com/ethereum-optimism/optimism/blob/33f06d2d5e4034125df02264a5ffe84571bd0359/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L48).

### `0x318A642db9e24A85318B8BF18eFd5287BA38643B` (`AnchorStateRegistryProxy`)

#### Game Type 0

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb49` <br/>
  **Before**: `0x00000000deaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddeaddead` <br/>
  **After**: `0xb5e152a45892717ad881031078cf0af24d224188cdaf1b16fcdba9657423c997` <br/>
  **Meaning**: Set the anchor state output root for game type 0 to `0xb5e152a45892717ad881031078cf0af24d224188cdaf1b16fcdba9657423c997`. This is the slot for the `anchors` mapping, which can be computed as `cast index uint 0 1`, where 0 is the game type and 1 is the slot of the `anchors` mapping.
  There's a public uni mainnet op-node RPC endpoint at `export OP_NODE_RPC=https://unichain-opn-geth-a-rpc-0-op-node.optimism.io/`) that you can use to verify the new root with:
  ```
  cast rpc --rpc-url $OP_NODE_RPC optimism_outputAtBlock $(cast th 5619555) | jq .outputRoot
  ```
  Note that the non-zero value _before_ was just a dummy value used during initial deployment, which explains why it's not set to zero.

- **Key**: `0xa6eef7e35abe7026729641147f7915573c7e97b47efa546f5f6e3230263bcb4a`<br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` (Note this may have changed if games of this type resolved)<br/>
  **After**: `0x000000000000000000000000000000000000000000000000000000000055bf63`<br/>
  **Meaning**: Set the anchor state L2 block number for game type 0 to `5619555` (cf. `cast th 5619555`). The slot number can be calculated using the same approach as above, and incremented by 1, based on the contract storage layout.

#### Game Type 1

This is the same as above for game type 0, but with different storage keys. The same output root and block number are used. This game is already being played, so the values _before_ may have changed.

- **Key**: `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f`<br/>
  **Before**: `0xa852e66c58d402434c3168bce2f2def736a30c3802be035f40cb0314c0de37fc` (May have changed!)<br/>
  **After**: `0xb5e152a45892717ad881031078cf0af24d224188cdaf1b16fcdba9657423c997`<br/>
  **Meaning**: Set the anchor state output root for game type 1 to `0xb5e152a45892717ad881031078cf0af24d224188cdaf1b16fcdba9657423c997`. This is the slot for the `anchors` mapping, which can be computed as `cast index uint 1 1`, where 1 is the game type and 1 is the slot of the `anchors` mapping.
  There's a public uni mainnet op-node RPC endpoint at `export OP_NODE_RPC=https://unichain-opn-geth-a-rpc-0-op-node.optimism.io/`) that you can use to verify the new root with:
  ```
  cast rpc --rpc-url $OP_NODE_RPC optimism_outputAtBlock $(cast th 5619555) | jq .outputRoot
  ```
  Note that the value _before_ may have changed if permissioned games were played in the meantime.

- **Key**: `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b6887930`<br/>
  **Before**: `0x00000000000000000000000000000000000000000000000000000000005210a4` (May have changed!)<br/>
  **After**: `0x000000000000000000000000000000000000000000000000000000000055bf63`<br/>
  **Meaning**: Set the anchor state L2 block number for game type 0 to `5619555` (cf. `cast th 5619555`). The slot number can be calculated using the same approach as above, and incremented by 1, based on the contract storage layout.
  Note that the value _before_ may have changed if permissioned games were played in the meantime.

### Nonce increments

The following nonce increments, and no others, must happen (key `0x05` on Safes):
- All simulations: PAO 3/3 `0x6d5B183F538ABB8572F5cD17109c617b994D5833`: `0` -> `1` 
- `council` simulation: SC Safe `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`: `10` -> `11` 
  - and a nonce increment for the owner EOA or Safe chosen for simulation, e.g. `0x07dC0893cAfbF810e3E72505041f2865726Fd073` for default index 0.
- `foundation` simulation: Fnd Safe `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`: `13` -> `14`
  - and a nonce increment for the owner EOA or Safe chosen for simulation, e.g. `0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64` for default index 0.
- `chain-governor` simulation: Uni Safe `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`: `5` -> `6`
  - and a nonce increment for the owner EOA or Safe chosen for simulation, e.g. `0xf89C1b6e5D65e97c69fbc792f1BcdcB56DcCde91` for default index 0.
