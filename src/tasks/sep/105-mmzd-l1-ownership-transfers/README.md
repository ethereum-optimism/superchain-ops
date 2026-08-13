# 105-mmzd-l1-ownership-transfers: Transfer L1 owners for Metal, Mode, Zora and Dust Sepolia (ProxyAdmin + DisputeGameFactory)

Status: READY TO SIGN

## Objective

Transfer L1 ownership of Metal Sepolia (chainId 1740), Mode Sepolia
(chainId 919), Zora Sepolia (chainId 999999999) and Dust Testnet
(chainId 55377) to the chain operator's designated Safe
`0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2`, executing the L1 half of the
ownership handover for all four chains in a single task. This is the Sepolia
counterpart of `eth/067-mmzd-l1-ownership-transfers`.

| Chain | Contract | Current owner | New owner |
|---|---|---|---|
| Metal Sepolia | ProxyAdmin `0xF7Bc4b3a78C7Dd8bE9B69B3128EEB0D6776Ce18A` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Metal Sepolia | DisputeGameFactoryProxy `0xd9A68F90B2d2DEbe18a916859B672D70f79eEbe3` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Mode Sepolia | ProxyAdmin `0xE7413127F29E050Df65ac3FC9335F85bB10091AE` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Mode Sepolia | DisputeGameFactoryProxy `0x7Bb634B42373A87712Da14064deD13Db8b8b14f4` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Zora Sepolia | ProxyAdmin `0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Zora Sepolia | DisputeGameFactoryProxy `0xA983A71253Eb74e5E86A4E4eD9F37113FC25f2BF` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Dust Testnet | ProxyAdmin `0x068881bd385BD917DdD9370f0DBFa19C969340D4` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Dust Testnet | DisputeGameFactoryProxy `0x157814873342A0f4D6758D69fdF11C4C40c01ed5` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |

All current owners verified on-chain 2026-08-13. There is no DelayedWETH
transfer on any chain — see [config.toml](./config.toml).

**Receiving Safe provenance:** `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2`
is a 1-of-1 Gnosis Safe v1.3.0 on Sepolia (sole owner
`0x23BA22Dd7923F3a3f2495bB32a6f3c9b9CD1EC6C`) — a much weaker setup than the
mainnet receiving Safe's 4-of-10, which is expected for a testnet. It was
designated by the chain operator (Conduit) as the receiving Safe for all four
chains on Sepolia, and confirmed against Conduit's address document plus the
address set exchanged over email (`support@conduit.xyz`) for a persistent
record. The same Safe already owns the Metal, Mode, Zora and Dust
`SystemConfigProxy` contracts on Sepolia.

The follow-up L2 ProxyAdmin transfers are `106-mmzd-l2pao-transfer`, which
must be executed after this task. The `SuperchainConfig` repoint and any
`SystemConfig` changes are out of scope — they will be executed by the
operator once it holds the ProxyAdmin.

## Signing gates — do not sign until ALL are cleared

1. **Receiving Safe verification:** re-confirm
   `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` with the chain operator
   through an authenticated channel, and verify it against this README with
   ≥2 OP Labs engineers. Ownership transfers are irreversible.
2. **Ordering / nonces:** this task is numbered after
   [sep/104](https://github.com/ethereum-optimism/superchain-ops/pull/1515)
   and is planned to execute after it. There is **no nonce coupling**:
   sep/104 is signed by the FoundationOperationsSafe, so the nonce pins in
   [config.toml](./config.toml) are the live values (L1PAO 54 / FUS 74 /
   SC 68, read 2026-08-13). They break only if another **L1PAO-signed**
   Sepolia task lands first — re-verify the live nonces immediately before
   signing and regenerate the [VALIDATION.md](./VALIDATION.md) hashes on any
   drift.

## Simulation & Signing

The root safe is the 2-of-2 nested L1PAO, so run each command once per child
safe (`foundation`, then `council`).

```bash
cd src/tasks/sep/105-mmzd-l1-ownership-transfers
SIMULATE_WITHOUT_LEDGER=1 just simulate <foundation|council>
# then, to sign:
just sign <foundation|council>
```

> [!CAUTION]
> The Safe nonces are pinned in `config.toml`. Re-verify them against live
> on-chain values before signing — see [VALIDATION.md](./VALIDATION.md).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes
and state changes. Task inputs and the rationale for the address fallback and
nonce overrides are documented in [config.toml](./config.toml).
