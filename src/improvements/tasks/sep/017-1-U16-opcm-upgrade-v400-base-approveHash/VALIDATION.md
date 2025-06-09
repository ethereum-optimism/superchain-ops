# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)
5. [Creating the safeTxHash](#creating-the-safetxhash)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Base Operations (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)
>
> - Domain Hash:  `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x44f68f329804d0f89c0b060335c2722ede577c1681ea3469ba4ce73308b1ccda`
>
> ### Base Security Council (`0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`)
>
> - Domain Hash:  `0x0127bbb910536860a0757a9c0ffcdf9e4452220f566ed83af1f27f9e833f0e23`
> - Message Hash: `0x2cc59dcd6ac9555cbb5cd4bab4aca8e617da8b6e011e5c1dfbc2d67581b6a9f5`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0xefdd941ed5432d7e7d17b7e60741a9581688f3458393d53b1acf9fc5b6861058`

## Understanding Task Calldata

The command to encode the calldata is:

```sh
# Encode the approve hash call for the hash that needs to be approved for task 017-2-U16-opcm-upgrade-v400-base.
cast calldata \
  "approveHash(bytes32)" \
  0x7b9cd304ef7df89dafa195a66528fb51b77990f5d1da6543873e51d481d46791

# This will print out the calldata for the approveHash call:
# 0xd4d9bdcd7b9cd304ef7df89dafa195a66528fb51b77990f5d1da6543873e51d481d46791

# Now encode the multicall payload, where `0x0fe884546476dDd290eC46318785046ef68a0BA9` is
# the address of the L1 ProxyAdmin Owner for Base.
cast calldata \
  "aggregate3Value((address,bool,uint256,bytes)[])" \
  '[(0x0fe884546476dDd290eC46318785046ef68a0BA9,false,0,0xd4d9bdcd7b9cd304ef7df89dafa195a66528fb51b77990f5d1da6543873e51d481d46791)]'
```

The resulting calldata:

```text
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000fe884546476ddd290ec46318785046ef68a0ba90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024d4d9bdcd7b9cd304ef7df89dafa195a66528fb51b77990f5d1da6543873e51d481d4679100000000000000000000000000000000000000000000000000000000
```

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) file.

### Task State Changes

### `0x0fe884546476ddd290ec46318785046ef68a0ba9` (ProxyAdminOwner (GnosisSafe))

- **Key:**          `0xa743cd50294216bdc457402c05234c3210a378d8e0ed4e86bbf0e42daa3b851d`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `approveHash(bytes32)` called on the Base Sepolia ProxyAdminOwner by the Base Nested Safe multisig.
- **Detail:** This slot change reflects an update to the `approvedHashes` mapping.
    To verify the slot yourself, run:
    - `res=$(cast index address 0x646132a1667ca7ad00d36616afba1a28116c770a 8)` - This is the BaseNestedSafe address.
    - `cast index bytes32 0x7b9cd304ef7df89dafa195a66528fb51b77990f5d1da6543873e51d481d46791 $res`
    - Please note: `0x7b9cd304ef7df89dafa195a66528fb51b77990f5d1da6543873e51d481d46791` is the safe transaction hash of the `approveHash` call. It should also match what's in the `config.toml` file. It's taken from the task: `017-2-U16-opcm-upgrade-v400-base`'s terminal output.

  ---

> [!IMPORTANT]
> Base Security Council Safe only

### `0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f` Base Security Council Safe

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `3`
  - **After:** `4`
  - **Summary:** Nonce
  - **Detail:** Nonce update for the Base Security Council Safe.

  ---

### `0x646132a1667ca7ad00d36616afba1a28116c770a` BaseNestedSafe

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `6`
  - **After:** `7`
  - **Summary:** Nonce
  - **Detail:** Nonce update for the parent multisig. This tasks template has it's `safeAddressString` set to `BaseNestedSafe` which is `0x646132a1667ca7ad00d36616afba1a28116c770a`.

> [!IMPORTANT]
> Base Security Council Safe only

- **Key:**      `0x7ae7c7e75c937dbf8398bcb3ae048eb139eb52b5800eb7b021fa1bd16cc39c64`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `approveHash(bytes32)` called on the BaseNestedSafe by the Base Security Council Safe.
  - **Detail:** This slot change reflects an update to the `approvedHashes` mapping.
    Specifically, this simulation was ran as the Base Security Council Safe `0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`. To verify the slot yourself, run:
    - `res=$(cast index address 0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f 8)`
    - `cast index bytes32 0x20fbba77794fb96cb7d0e3be668f05d1a3852ade7eb3e595ff6a4165a444a5a7 $res`
    - Please note: `0x20fbba77794fb96cb7d0e3be668f05d1a3852ade7eb3e595ff6a4165a444a5a7` is the hash to approve on the Base Nested Safe. It's denoted as `Parent hashToApprove` in the task: `017-2-U16-opcm-upgrade-v400-base`'s terminal output.

> [!IMPORTANT]
> Base Operations Safe only

- **Key:**      `0x4270791d90a3ce723467026915723e93d9ea66471005bd4708981f33b95fc76f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `approveHash(bytes32)` called on the BaseNestedSafe by the Base Security Council Safe.
  - **Detail:** This slot change reflects an update to the `approvedHashes` mapping.
    Specifically, this simulation was ran as the Base Security Council Safe `0x6AF0674791925f767060Dd52f7fB20984E8639d8`. To verify the slot yourself, run:
    - `res=$(cast index address 0x6AF0674791925f767060Dd52f7fB20984E8639d8 8)`
    - `cast index bytes32 0x20fbba77794fb96cb7d0e3be668f05d1a3852ade7eb3e595ff6a4165a444a5a7 $res`
    - Please note: `0x20fbba77794fb96cb7d0e3be668f05d1a3852ade7eb3e595ff6a4165a444a5a7` is the hash to approve on the Base Nested Safe. It's denoted as `Parent hashToApprove` in the task: `017-2-U16-opcm-upgrade-v400-base`'s terminal output.

  ---

> [!IMPORTANT]
> Base Operations Safe only  

### `0x6AF0674791925f767060Dd52f7fB20984E8639d8` Base Operations Safe

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `8`
  - **After:** `9`
  - **Summary:** Nonce
  - **Detail:** Nonce update for the Base Operations Safe.

---

  ### Nonce increments

- The remaining nonce increments are for the Safes and EOAs that are involved in the simulation.
  The details are described in the generic [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) document.
  - <sender-address> - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe (if you're simulating)).

### Creating the safeTxHash

Open chisel in the terminal and run the following command to create the `safeTxHash`:
```bash
bytes32 domainSeparator = keccak256(abi.encode(0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218, 11155111, 0x0fe884546476dDd290eC46318785046ef68a0BA9));
bytes32 safeTxHash = keccak256(
        abi.encode(
            0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8,
            0x93dc480940585D9961bfcEab58124fFD3d60f76a,
            0,
            keccak256(hex"82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000044c191ce5ce35131e703532af75fa9ca221e23980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000000000000000000000000000000000000"),
            uint8(1),
            0,
            0,
            0,
            address(0),
            address(0),
            24
        )
);
keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, safeTxHash))
```