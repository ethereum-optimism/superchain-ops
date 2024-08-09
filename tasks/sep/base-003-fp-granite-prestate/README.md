# Sepolia FP Upgrade - Granite Prestate Update

Status: READY TO SIGN

## Objective

Upgrades the `FaultDisputeGame` to a new implementation with the `ABSOLUTE_PRESTATE` set for the upcoming Granite
hardfork. The `MIPS` VM, `PreimageOracle`, and `AnchorStateRegistry` from the existing deployment are re-used.

The `ABSOLUTE_PRESTATE` for this release is that of the `op-program/v1.3.0-rc.2` tag. To reproduce it locally:

```sh
git clone git@github.com:ethereum-optimism/optimism && \
  cd optimism && \
  git checkout op-program/v1.3.0-rc.2 && \
  make reproducible-prestate && \
  cat ./op-program/bin/prestate-proof.json | jq -r .pre
```

## Pre-deployments

The `FaultDisputeGame` has been deployed at [`0xDa35a941D76ff37A4abd877156F58E6Aa2e499b0`](https://sepolia.etherscan.io/address/0xDa35a941D76ff37A4abd877156F58E6Aa2e499b0).

The `PermissionedDisputeGame` has been deployed at [`0x8105D699B38eD7CF9b75353BaCccA60496Ed72Fd`](https://sepolia.etherscan.io/address/0x8105D699B38eD7CF9b75353BaCccA60496Ed72Fd).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/base-003-fp-granite-prestate/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade changes the `ABSOLUTE_PRESTATE` in the `FaultDisputeGame` and `PermissionedDisputeGame` to that of the `op-program/v1.3.0-rc.2` tag in preparation for the Granite hardfork.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `FaultDisputeGame`

Upgrades the implementation of the `FaultDisputeGame` in the `DisputeGameFactory` to contain the updated absolute prestate value.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000da35a941d76ff37a4abd877156f58e6aa2e499b0`

### Inputs

**\_gameType:** `0`

**\_impl:** `0xDa35a941D76ff37A4abd877156F58E6Aa2e499b0`

## Tx #2: Upgrade `PermissionedDisputeGame`

Upgrades the implementation of the `PermissionedDisputeGame` in the `DisputeGameFactory` to contain the updated absolute prestate value.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000010000000000000000000000008105d699b38ed7cf9b75353baccca60496ed72fd`

### Inputs

**\_gameType:** `1`

**\_impl:** `0x8105D699B38eD7CF9b75353BaCccA60496Ed72Fd`
