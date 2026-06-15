# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: reviewed in Tenderly via the link printed during simulation (L1 deposits) and on the L2 once relayed.

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0x5a442cc9643cbebe6262307d5b4636da5e06b4de42010e1a75880760bd3f9389`
> - Safe Hash:    `0x0bd45f677139f6c89c4ee904c5f9c4c852d970affc7f81b3d7f7b0c5da70ec62`
>
> _Hashes generated via `just simulate` at the latest block with the PAO nonce override in [config.toml](./config.toml) (= 112, i.e. live nonce 111 + 1 for task 102 executing first). If that ordering/override changes, or the recipients change, re-run `just simulate` and replace the Message/Safe hashes before signing._

## Understanding Task Calldata

The task assembles **7 `OptimismPortal2.depositTransaction` calls** through `Multicall3.aggregate3Value`, targeting the `migration-src-0` `OptimismPortalProxy` (`0x7b123dD7466dAB1fe60703Cd11fCE9c77d413a05`):

1. 3 × CREATE2 deploy of the v1.6.0 fee-vault impl bytecode on L2 (SequencerFeeVault; a shared BaseFeeVault/L1FeeVault impl; OperatorFeeVault).
2. 4 × `ProxyAdmin.upgradeAndCall(proxy, impl, initialize(recipient, 0, WithdrawalNetwork.L1))` — one per vault.

The exact deposit calldata (deterministic CREATE2 addresses + per-vault `initialize` args) is assembled by the template and printed during simulation. Confirm the 4 upgrade calls target the 4 predeploys with the 4 recipients listed below, and that each `initialize` passes `minWithdrawalAmount = 0` and `withdrawalNetwork = 0` (L1).

## Task State Changes

### migration-src-0 L2 (chainId 420120140) — applied once portal deposits are relayed

| L2 Predeploy | RECIPIENT() (new) | MIN_WITHDRAWAL_AMOUNT() | WITHDRAWAL_NETWORK() |
|--------------|-------------------|-------------------------|----------------------|
| `0x4200…0011` SequencerFeeVault | `0xdead000000000000000000000000000000000011` | `0` | `0` (L1) |
| `0x4200…0019` BaseFeeVault | `0xdead000000000000000000000000000000000019` | `0` | `0` (L1) |
| `0x4200…001a` L1FeeVault | `0xdead00000000000000000000000000000000001a` | `0` | `0` (L1) |
| `0x4200…001b` OperatorFeeVault | `0xdead00000000000000000000000000000000001b` | `0` | `0` (L1) |

Each proxy's implementation slot is set to the corresponding CREATE2-deployed v1.6.0 implementation.

### `0xe934Dc97E347C6aCef74364B50125bb8689c40ff` (ProxyAdminOwner) — L1

Nonce increments by 1. (Plus the L1 portal `depositTransaction` events for the 7 deposits.)

## Post-execution verification

```bash
cast call 0x4200000000000000000000000000000000000011 "RECIPIENT()(address)" --rpc-url https://migration-src-0.optimism.io
# Expected: 0xdEAD000000000000000000000000000000000011
# ...repeat for 0x…0019, 0x…001a, 0x…001b
```

Record the executed tx hash in the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) under the FeeVault recipient update step.
