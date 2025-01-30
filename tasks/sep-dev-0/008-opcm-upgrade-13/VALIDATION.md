# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Nested Safe State Overrides and Changes

This task is executed by the nested 2/2 `ProxyAdminOwner` Safe. Refer to the
[generic nested Safe execution validation document](../../../NESTED-VALIDATION.md)
for the expected state overrides and changes.

The `approvedHashes` mapping **key** of the `ProxyAdminOwner` that should change during the simulation is
- Council simulation: `0x7a680028073e956784e910c02dd0a0936604b29cd9f9c71c9d8e568533821e16`
- Foundation simulation: `0xd30a77d4a810ba7768ba1bd52de1cbb869f7b641c57132e46544f044cd7e839a`

calculated as explained in the nested validation doc:
```sh
cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8 # council
# 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
cast index bytes32 0x7b390cc232cd3a45f1100c184953b4e6a6556fe2af978d76b577a87a65345254 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
# 0x7a680028073e956784e910c02dd0a0936604b29cd9f9c71c9d8e568533821e16
```

```sh
cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8 # foundation
# 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
cast index bytes32 0x7b390cc232cd3a45f1100c184953b4e6a6556fe2af978d76b577a87a65345254 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
# 0xd30a77d4a810ba7768ba1bd52de1cbb869f7b641c57132e46544f044cd7e839a
```

## State Changes

