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
> - Message Hash: `0x36bbfb34f0d0dfb7c558ccf273159cab06e8f3c2fe70060bab5a108ff7714928`
> - Safe Hash:    `0xea3f3fc2dd53d15841965d1cc91ea3319323ea0c696ac944489f35c83a2cf08b`
>
> _Hashes generated with PAO Safe nonce stateOverride = 97 (stacked after 076). For standalone simulation use 96; re-run `just simulate` and replace before signing._

## Task Calldata

Calldata routes via Multicall3 → `AnchorStateRegistry.setRespectedGameType(0)` on the migrations-sop-1 ASR (`0x8Faf920fAd8138DeBF666949b9e41ff71Cce1C5a`). Authorization is `SystemConfig.guardian()` which on this chain == PAO Safe (`0xe934…40ff`), so the template's default `safeAddressString="GuardianSafe"` is overridden to `"ProxyAdminOwner"` in `config.toml`.

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000008faf920fad8138debf666949b9e41ff71cce1c5a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000247fc48504000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

EIP-712 digest (Safe v1.4.1):
```
0x190107e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e36bbfb34f0d0dfb7c558ccf273159cab06e8f3c2fe70060bab5a108ff7714928
```
