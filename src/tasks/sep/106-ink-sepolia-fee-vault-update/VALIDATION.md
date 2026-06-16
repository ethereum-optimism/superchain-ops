# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

> [!CAUTION]
> This task is **blocked** — see [README.md](./README.md#blockers). The recipients are placeholders and Ink Sepolia's L2 ProxyAdmin owner is `address(0)` (the L2 upgrade would revert). Do not sign until both are resolved.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: reviewed in Tenderly via the link printed during simulation (L1 deposits) and on the L2 once relayed.

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task. This is a **nested** task signed by the L1 ProxyAdminOwner's two owner safes; verify the hashes for whichever safe you are signing with.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x05e665dc92c0c129ab42f22c3f3047ea85b37114dc74d557656700a4e890e0c3`
>
> ### Foundation Upgrade Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0xdb657084541966763ac3506de3a97f09884fbd4bedfbe134a07df39ef36bcd4d`
>
> _The Domain Hashes are deterministic for these safes on Sepolia (chainId 11155111): `keccak256(abi.encode(0x47e7…9218, 11155111, <safe>))`. The Message hashes were generated against live Sepolia state on 2026-06-16 with the **placeholder** `0xdead…` recipients and signer-safe nonces L1PAO=54 / Foundation=74 / Security Council=68. They are **provisional** — they change when the real recipients are set and whenever the signer-safe nonces advance; regenerate via `just simulate` before signing._

## Understanding Task Calldata

The task assembles **7 `OptimismPortal2.depositTransaction` calls** through `Multicall3.aggregate3Value`, targeting the Ink Sepolia `OptimismPortalProxy` (`0x5c1d29C6c9C8b0800692acC95D700bcb4966A1d7`):

1. 3 × CREATE2 deploy of the v1.6.0 fee-vault impl bytecode on L2 (SequencerFeeVault; a shared BaseFeeVault/L1FeeVault impl; OperatorFeeVault).
2. 4 × `ProxyAdmin.upgradeAndCall(proxy, impl, initialize(recipient, 0, WithdrawalNetwork.L1))` — one per vault.

The exact deposit calldata (deterministic CREATE2 addresses + per-vault `initialize` args) is assembled by the template and printed during simulation. Confirm the 4 upgrade calls target the 4 predeploys with the 4 recipients in [config.toml](./config.toml), and that each `initialize` passes `minWithdrawalAmount = 0` and `withdrawalNetwork = 0 (L1)`.

## Task State Changes

### Ink Sepolia L2 (chainId 763373) — applied once portal deposits are relayed AND Blocker #2 is cleared

| L2 Predeploy | recipient() (new, placeholder) | minWithdrawalAmount() | withdrawalNetwork() |
|--------------|--------------------------------|-----------------------|---------------------|
| `0x4200…0011` SequencerFeeVault | `0xdead000000000000000000000000000000000011` | `0` | `0` (L1) |
| `0x4200…0019` BaseFeeVault | `0xdead000000000000000000000000000000000019` | `0` | `0` (L1) |
| `0x4200…001a` L1FeeVault | `0xdead00000000000000000000000000000000001a` | `0` | `0` (L1) |
| `0x4200…001b` OperatorFeeVault | `0xdead00000000000000000000000000000000001b` | `0` | `0` (L1) |

Each proxy's implementation slot is set to the corresponding CREATE2-deployed v1.6.0 implementation.

> [!WARNING]
> While the L2 ProxyAdmin owner is `address(0)` (Blocker #2), the relayed `upgradeAndCall` deposits **revert on L2** and none of the above state changes take effect, even though the L1 `depositTransaction` events succeed.

### Signer safes — L1

`Security Council` and `Foundation Upgrade Safe` nonces increment by 1 (nested execution through the L1 ProxyAdminOwner `0x1Eb2fF…56E2`). Plus the L1 portal `depositTransaction` events for the 7 deposits.

## Post-execution verification

```bash
cast call 0x4200000000000000000000000000000000000011 "recipient()(address)" --rpc-url https://rpc-gel-sepolia.inkonchain.com
# Expected (once real recipient is set): the configured Kraken recipient
# ...repeat for 0x…0019, 0x…001a, 0x…001b
```

Record the executed tx hash in the migration plan execution log (step 15 / FeeVault recipient update).
