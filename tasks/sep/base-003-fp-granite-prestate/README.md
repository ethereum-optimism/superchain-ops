# Sepolia FP Upgrade - Granite Prestate Update

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x2f2ce171fab5c56b31e8b1b7dc33ca0453d00e7b09c7317302916b2be98b7a0e)

## Objective

Upgrades the `FaultDisputeGame` to a new implementation with the `ABSOLUTE_PRESTATE` set for the upcoming Granite
hardfork. The `MIPS` VM, `PreimageOracle`, and `AnchorStateRegistry` from the existing deployment are re-used.

The `ABSOLUTE_PRESTATE` for this release is that of the `op-program/v1.3.0-rc.3` tag. To reproduce it locally:

```sh
git clone git@github.com:ethereum-optimism/optimism && \
  cd optimism && \
  git checkout op-program/v1.3.0-rc.3 && \
  make reproducible-prestate && \
  cat ./op-program/bin/prestate-proof.json | jq -r .pre
```

## Pre-deployments

The `FaultDisputeGame` has been deployed at [`0x48F9F3190b7B5231cBf2aD1A1315AF7f6A554020`](https://sepolia.etherscan.io/address/0x48F9F3190b7B5231cBf2aD1A1315AF7f6A554020).

The `PermissionedDisputeGame` has been deployed at [`0x54966d5A42a812D0dAaDe1FA2321FF8b102d1ee1`](https://sepolia.etherscan.io/address/0x54966d5A42a812D0dAaDe1FA2321FF8b102d1ee1).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/base-003-fp-granite-prestate/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade changes the `ABSOLUTE_PRESTATE` in the `FaultDisputeGame` and `PermissionedDisputeGame` to that of the `op-program/v1.3.0-rc.3` tag in preparation for the Granite hardfork.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `FaultDisputeGame`

Upgrades the implementation of the `FaultDisputeGame` in the `DisputeGameFactory` to contain the updated absolute prestate value.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048f9f3190b7b5231cbf2ad1a1315af7f6a554020`

### Inputs

**\_gameType:** `0`

**\_impl:** `0x48F9F3190b7B5231cBf2aD1A1315AF7f6A554020`

## Tx #2: Upgrade `PermissionedDisputeGame`

Upgrades the implementation of the `PermissionedDisputeGame` in the `DisputeGameFactory` to contain the updated absolute prestate value.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3000000000000000000000000000000000000000000000000000000000000000100000000000000000000000054966d5a42a812d0daade1fa2321ff8b102d1ee1`

### Inputs

**\_gameType:** `1`

**\_impl:** `0x54966d5A42a812D0dAaDe1FA2321FF8b102d1ee1`
