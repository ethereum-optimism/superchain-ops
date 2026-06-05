# Validation

Task 095 — karst-u19-beta-0 (permissioned correction, part 2/2): zero the CANNON_KONA (game type
8) implementation. Runs after 094.

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): `[[konaGameImplConfig]]` impl = `0x0` (disable path),
   gameArgs empty; FDG/PDG are passthroughs.
3. State change: the template `_validate` asserts gameImpls(8)==`0x0` with empty gameArgs;
   gameImpls(0)/gameImpls(1) unchanged.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Pinned at the single sequential alpha/beta batch nonce **13** (after 091/092/093/094). The PAO
> Safe `0x8E851…` is shared — re-verify against your ledger and the terminal at signing.
>
> Regenerated for the pinned nonce **13** (after 091/092/093/094).
>
> ### Betanet 1/N Safe (`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`)
>
> - Domain Hash:  `0x85cc686e8cbc7571a70994af7e216c5525d22203d359558d46a795125c38de14`
> - Message Hash: `0x37085f355b46bc63b04200676906ff3602ba67a2cf16a93554cd069cff199cdb`
