# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes):
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file, which includes links to the relevant Superchain Registry sources.
3. State Changes: the template's _validate block includes assertions to confirm the task ran correctly. State Changes can also be manually reviewed in Tenderly, using the link shown in the terminal during simulation.

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
>
> ### Migrations-sop-1 1/1 Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0xa8819d7b528939a1a64313501b199a754e74cc90ea359f567287a78fe873f2f8`
> - Safe Hash:    `0xdd48f5694ebc64089cadc0724a1aaed4bae04c16bde9868b816f90c32d6c500f`
>
> _Hashes generated with PAO Safe nonce stateOverride = 101 (stacked after U19 betanet tasks 076-079 + task 080, all of which share this Safe). For standalone simulation use 96; re-run `just simulate` and replace before signing._

## Task Calldata

Calldata routes via Multicall3 → `AnchorStateRegistry.setRespectedGameType(0)` on the migrations-sop-1 ASR (`0x8Faf920fAd8138DeBF666949b9e41ff71Cce1C5a`). Authorization is `SystemConfig.guardian()` which on this chain == PAO Safe (`0xe934…40ff`), so the template's default `safeAddressString="GuardianSafe"` is overridden to `"ProxyAdminOwner"` in `config.toml`.

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000008faf920fad8138debf666949b9e41ff71cce1c5a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000247fc48504000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

EIP-712 digest (Safe v1.4.1):
```
0x190107e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61ea8819d7b528939a1a64313501b199a754e74cc90ea359f567287a78fe873f2f8
```
