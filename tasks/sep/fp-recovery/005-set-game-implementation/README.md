# ProxyAdminOwner - Set Dispute Game Implementation

Status: CONTINGENCY TASK, SIGN AS NEEDED

## Objective

This task sets the implementation for game type _TODO:game type_ to _TODO:new implementation address_.

## Tx #1: Set game implementation in the `DisputeGameFactoryProxy`

Sets the game type implementation contract.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3<game-type><implementation-addr>`

### Inputs

**\_gameType:** `<user-input>`

**\_impl:** `<user-input>`

## Preparing the Operation

1. Copy this directory to the appropriate final task location.

2. Update the path in `NestedSignFromJson.s.sol` `setUp` function to the new location

3. Update the relative path to lib/superchain-registry in `justfile` if needed.

4. Set the `L1_CHAIN_NAME` and `L2_CHAIN_NAME` configuration to the appropriate chain in the `.env` file.

5. Generate the batch with `just generate-input <gameType> <newImplAddr>`.

6. Collect signatures and execute the action according to the instructions in [NESTED.md](../../../NESTED.md).

### State Validations

The two state modifications that are made by this action are:

1. An update to the nonce of the Gnosis safe owner of the `ProxyAdminOwner`.
2. An update to the `gameImpls` mapping in `DisputeGameFactoryProxy`.
