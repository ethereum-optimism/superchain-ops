# ProxyAdminOwner - Set Dispute Game Implementation

Status: CONTINGENCY TASK, SIGN AS NEEDED

## Objective

This template provides the ability to set fault dispute game implementations for one or more game types. In particular
it is useful for updating the absolute prestate for the fault dispute game as part of a hard fork and for adding a new
supported game type such as enabling permissionless games.

## Preparing the Operation

1. Run `just prep <l1> <l2>` to prepare the initial files. e.g. `just prep sepolia op` The result is stored in the `out`
   directory.

2. Add the required transactions to the batch (see below).

3. Review the assertions in `out/NestedSignFromJson.s.sol` `_precheckDisputeGameImplementation` function.
   The template assertions check that properties of the new implementation match the old one if it exists.
   No checks are performed if there is no prior implementation, in which case it is recommended to implement custom
   checks.

4. Add additional information to the `README.md` to explain the purpose of the operation (the generated version just
   states what will change but not why).

5. Copy the `out` directory to the appropriate final task location (e.g. `tasks/sep/XXX-upgrade-dispute-game`).

6. Collect signatures and execute the action according to the instructions in [NESTED.md](../../../../NESTED.md).

### Adding Transactions

The batch can be created with an arbitrary number of transactions to set the implementation of multiple game types in a
single batch. For each game type to set, run:

```
just set-implementation <gameType> <newImplAddr>
```

To remove all added transactions, run `just clean`. Note that you need to run `just prep <l1> <l2>` again after clean.

#### Example - Upgrading for a Hard Fork

To prepare the task to upgrade both `CANNON` (0) and `PERMISSIONED` (1) game types on op-sepolia for a new hard fork,
run:

```bash
just clean prep sepolia op
just set-implementation 0 <cannon-game-impl>
just set-implementation 1 <permissioned-game-impl>
```

### Generated Documentation

The `out/README.md` and `out/VALIDATION.md` files are generated based on the transactions that are added to the batch.
