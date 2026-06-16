# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's `_validate` block asserts the new `gameArgs(1)` and unchanged `gameImpls(1)`. State changes can also be reviewed in Tenderly via the link printed during simulation.

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0xfa328de0d675dc73744a57cc2dee420747640bc257882c27887e6d41e8a22b11`
> - Safe Hash:    `0x903c07f6e413342527ee5dda00d8b64af80477cab0ea64abe1bb7a7ac80fb598`
>
> _Hashes generated via `just simulate` at the latest block with the PAO nonce override in [config.toml](./config.toml) (= 111, the live on-chain nonce; 102 is the first PAO-signed task in this exercise). If the override changes (e.g. another PAO task executes first), re-run `just simulate` and replace the Message/Safe hashes before signing._

## Understanding Task Calldata

The task calls `setImplementation` **once** on the `migration-src-0` DisputeGameFactory (`0xD36035054813F3979f61fE17E870beC0fB8F964D`), for PDG (game type 1). The implementation address does not change; only the `gameArgs` blob changes.

> **Note:** The effective change vs current on-chain state is:
> - **PDG (game type 1)** proposer: `0x0fd61abe…c9fc` → `0xD3E481Ac…442b` (`migration-dest-0` receiving infra)
> - **PDG (game type 1)** challenger: `0x5d5f9c4b…1546e` → `0x4DFb8C08…1594` (`migration-dest-0` receiving infra)
> - **PDG (game type 1)** prestate: `0x038512e0…d54c` → `0xdead…` (`0xdead` placeholder)

Verify the inner calldata fingerprint:

```bash
cast calldata "setImplementation(uint32,address,bytes)" 1 \
  0x58bf355C5d4EdFc723eF89d99582ECCfd143266A \
  0xdead0000000000000000000000000000000000000000000000000000000000006463dee3828677f6270d83d45408044fc5edb90825189fec7e5794e6cbb53afcfe624c517537a2163895dcd2f5ddd092c31aa8744ceb4c6006b7ea8e00000000000000000000000000000000000000000000000000000000190a864cd3e481acf11fb35c1b274342ea3137c7ec29442b4dfb8c08220d7ae47acd6aeed15a06ecc2f61594
# Selector + head: 0xb1070957…0000000000000000000000000000000000000000000000000000000000000001
#                          (gameType = 1, impl = 0x58bf355C…266A, gameArgs = the 164-byte blob above)
```

The new 164-byte `gameArgs` blob must contain, in order: prestate `0xdead…` (`0xdead` placeholder), vm `0x6463dee3…b908`, ASR `0x25189fec…a216`, delayedWETH `0x3895dcd2…ea8e`, chainId `190a864c` (420120140), proposer `d3e481ac…442b`, challenger `4dfb8c08…1594`.

The outer Multicall3 blob is assembled by the framework and printed during simulation; confirm it contains only the single `setImplementation` call above.

## Task State Changes

### `0xD36035054813F3979f61fE17E870beC0fB8F964D` (DisputeGameFactoryProxy) — Chain ID 420120140

- `gameArgs` for **game type 1 (PERMISSIONED_CANNON)** updated to embed the new `migration-dest-0` proposer (`0xD3E481Acf11fB35c1b274342ea3137c7ec29442b`) and challenger (`0x4DFb8C08220d7aE47ACd6AEed15A06eCc2f61594`), and to set the prestate to the `0xdead…` placeholder. The implementation address (`0x58bf355C…266A`) is unchanged.
- Game type 0 (CANNON / FDG) is untouched and remains unset.

### `0xe934Dc97E347C6aCef74364B50125bb8689c40ff` (ProxyAdminOwner)

Nonce increments by 1.

## Post-execution verification

```bash
cast call 0xD36035054813F3979f61fE17E870beC0fB8F964D "gameArgs(uint32)(bytes)" 1 --rpc-url <SEPOLIA_RPC>
# Bytes 0..32    (prestate)   must equal dead000000000000000000000000000000000000000000000000000000000000
# Bytes 124..144 (proposer)  must equal d3e481acf11fb35c1b274342ea3137c7ec29442b
# Bytes 144..164 (challenger) must equal 4dfb8c08220d7ae47acd6aeed15a06ecc2f61594
```

Record the executed tx hash in the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) under the DisputeGameFactory proposer/challenger rotation step.
