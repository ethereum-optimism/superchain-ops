# Validation

Task 095 — karst-u19-beta-0 (permissioned correction, part 1/2): revert `respectedGameType` 8 → 1.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): `{chainId = 420110023, gameType = 1}`.
3. State change: the template `_validate` asserts `ASR.respectedGameType() == 1`.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> beta-0 correction is a **separate signing batch** (grouping B). Hash captured at the assumed
> combined-stack nonce **11** (after alpha 092/093/094). If beta-0 is signed/executed in its own
> batch ahead of the alpha rollout, the nonce will differ — re-pin and regenerate. Re-verify
> against your ledger and the terminal at signing.
>
> ### Betanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0x859d1f5eeaab6e386708ba28fe7993dda187cdda8e3aa65ac8b08d4349f3e775`
