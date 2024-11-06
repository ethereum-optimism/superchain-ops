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
single batch. 

#### Set Game Implementation

For each game type to set, run:

```
just set-implementation <gameType> <newImplAddr>
```

#### Re-initialize AnchorStateRegistry

To add a new game type to the AnchorStateRegistry, it needs to be re-initialized to set an initial anchor state for the
new game type. To add the transactions required for this run:

```
just copy-anchor-state <fromGameType> <toGameTypes>
```

where `<fromGameType>` is the existing game type to load the current game type from and `<toGameTypes>` is the game
types to copy the anchor state to. The anchor state to set is taken _at the time the just command is run_. The task is
then created with a fixed anchor state to set which may roll back later updates to the game type on-chain if games 
resolve after the `just` command is run to add the transaction to the task definition. However this only affects the 
game types in `<toGameTypes>`, other anchor states are left unchanged.

#### Removing All Transactions

To remove all added transactions, run `just clean`. Note that you need to run `just prep <l1> <l2>` again after clean.

#### Example - Upgrading for a Hard Fork

To prepare the task to upgrade both `CANNON` (0) and `PERMISSIONED` (1) game types on op-sepolia for a new hard fork,
run:

```bash
just clean prep sepolia op
just set-implementation 0 <cannon-game-impl>
just set-implementation 1 <permissioned-game-impl>
```
#### Example - Adding Permissionless Dispute Game

To prepare the task to set an implementation for `CANNON` (0) and copy the `PERMISSIONED` anchor state to be its initial
anchor state run:

```bash
just clean prep sepolia op
just set-implementation 0 <cannon-game-impl>
just copy-anchor-state 1 0
```

### Generated Documentation

The `out/README.md` and `out/VALIDATION.md` files are generated based on the transactions that are added to the batch.
