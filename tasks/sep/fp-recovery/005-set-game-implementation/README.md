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

2. Review the assertions in `NestedSignFromJson.s.sol` `_precheckDisputeGameImplementation` function.
   The template assertions check that properties of the new implementation match the old one if it exists.
   No checks are performed if there is no prior implementation, in which case it is recommended to implement custom
   checks.

3. Set the `L1_CHAIN_NAME` and `L2_CHAIN_NAME` configuration to the appropriate chain in the `.env` file.

4. Add the required transactions to the batch (see below).

5. Collect signatures and execute the action according to the instructions in [NESTED.md](../../../NESTED.md).

### Adding Transactions

The batch can be created with an arbitrary number of transactions to set the implementation of multiple game types in a
single batch. For each game type to set, run:

```
just set-implementation <gameType> <newImplAddr>
```

To remove all added transactions, run `just clean`.

### State Validations

The two state modifications that are made by this action are:

1. An update to the nonce of the Gnosis safe owner of the `ProxyAdminOwner`.
2. An update to the `gameImpls` mapping in `DisputeGameFactoryProxy` for each game type being set.
