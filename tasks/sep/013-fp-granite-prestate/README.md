# Sepolia FP Upgrade - Granite Prestate Update

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xfe610500768bc2abe92d23c86ac0bb2a9d2e086193214e104e8fb930090c679d)

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

The `FaultDisputeGame` has been deployed at [`0x19e9d5a58Cbc82120C8AB163bE2aE544ECF4B802`](https://sepolia.etherscan.io/address/0x19e9d5a58cbc82120c8ab163be2ae544ecf4b802).

The `PermissionedDisputeGame` has been deployed at [`0x7ef30b65d49229fc97d4b45bfcf3c435b179771f`](https://sepolia.etherscan.io/address/0x7ef30b65d49229fc97d4b45bfcf3c435b179771f).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/013-fp-granite-prestate/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade changes the `ABSOLUTE_PRESTATE` in the `FaultDisputeGame` and `PermissionedDisputeGame` to that of the `op-program/v1.3.0-rc.3` tag in preparation for the Granite hardfork.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `FaultDisputeGame`

Upgrades the implementation of the `FaultDisputeGame` in the `DisputeGameFactory` to contain the updated absolute prestate value.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000078f2b801730dbd937fe2e209afb3e1cdf3c460bc`

### Inputs

**\_impl:** `0x78F2B801730DBD937Fe2e209aFB3E1CdF3c460Bc`

**\_gameType:** `0`

## Tx #2: Upgrade `PermissionedDisputeGame`

Upgrades the implementation of the `PermissionedDisputeGame` in the `DisputeGameFactory` to contain the updated absolute prestate value.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000010000000000000000000000004873712bdb5fe5b3487bf0a48fff1cdfba794cfd`

### Inputs

**\_gameType:** `1`

**\_impl:** `0x4873712BdB5Fe5B3487Bf0A48FfF1Cdfba794CFD`
