# Validation

Task 094 — karst-u19-beta-0 (permissioned correction, part 1/2): revert `respectedGameType` 8 → 1.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): `{chainId = 420110023, gameType = 1}`.
3. State change: the template `_validate` asserts `ASR.respectedGameType() == 1`.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Pinned at the single sequential alpha/beta batch nonce **12** (after 091/092/093). The PAO Safe
> `0x8E851…` is shared — re-verify against your ledger and the terminal at signing.
>
> Regenerated for the pinned nonce **12** (after 091/092/093).
>
> ### Betanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0xd09369d0bf518f7e5c7c3ecfbe11e2372f2e11ff94f70d3613178c7bfb55873f`
