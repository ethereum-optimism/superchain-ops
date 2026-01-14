# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Validate the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Single Safe Signer Data
>
> - Domain Hash: `0x2e5ad244d335c45fbace4ebd1736b0fad81b01591a2819baedad311ead5bce76`
> - Message Hash: `0xf9e7cca4843c0e3c21b30784f5e3363dc067a2fb6bb646e2c16bacc8c9db7dd0`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for enabling SaferSafes on the Foundation Operations Safe.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved plan with no unexpected modifications or side effects.

### Overview

This task performs three operations via Multicall3DelegateCall:

1. **Set Guard to zero** - Clears any existing guard (already zero for FoS)
2. **Enable SaferSafes Module** - Adds SaferSafes to the Safe's module list
3. **Configure Liveness Module** - Sets the liveness response period and fallback owner on SaferSafes

### Call 1: Set Guard to zero

```bash
cast calldata 'setGuard(address)' 0x0000000000000000000000000000000000000000
# Output: 0xe19a9dd90000000000000000000000000000000000000000000000000000000000000000
```

### Call 2: Enable SaferSafes Module

```bash
cast calldata 'enableModule(address)' 0xA8447329e52F64AED2bFc9E7a2506F7D369f483a
# Output: 0x610b5925000000000000000000000000a8447329e52f64aed2bfc9e7a2506f7d369f483a
```

### Call 3: Configure Liveness Module on SaferSafes

The `configureLivenessModule` function is called with a `ModuleConfig` struct:
- `livenessResponsePeriod`: 2592000 (30 days in seconds, hex: 0x278d00)
- `fallbackOwner`: 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 (Security Council)

```bash
cast calldata 'configureLivenessModule((uint256,address))' "(2592000,0xc2819DC788505Aac350142A7A707BF9D03E3Bd03)"
# Output: 0x05ccf6060000000000000000000000000000000000000000000000000000000000278d00000000000000000000000000c2819dc788505aac350142a7a707bf9d03e3bd03
```

### Inputs to `Multicall3DelegateCall`

The three calls above are batched via `Multicall3DelegateCall.aggregate3Value()`:

| Call | Target | Description |
|------|--------|-------------|
| 1 | `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` | FoS: setGuard(address(0)) |
| 2 | `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` | FoS: enableModule(SaferSafes) |
| 3 | `0xA8447329e52F64AED2bFc9E7a2506F7D369f483a` | SaferSafes: configureLivenessModule(...) |

## State Changes

### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (FoundationOperationsSafe)

| Key | Before | After | Description |
|-----|--------|-------|-------------|
| `0x0000000000000000000000000000000000000000000000000000000000000005` | `113` | `114` | Safe nonce increment |
| `0x073d01777a7e5521317f64ce51f98946a042c5bdcaec99ecde1a1793ecae1afc` | `0x0` | `0x1` | `modules[SaferSafes]` → points to SENTINEL |
| `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` | `0x1` | `0x...a8447329e52f64aed2bfc9e7a2506f7d369f483a` | `modules[SENTINEL]` → points to SaferSafes |

#### Slot Derivations

The Gnosis Safe stores modules in a linked list mapping at storage slot 1. The slot for each entry is computed as:

```
slot = keccak256(abi.encode(moduleAddress, 1))
```

**SENTINEL_MODULES slot:**
```bash
cast keccak $(cast abi-encode 'f(address,uint256)' 0x0000000000000000000000000000000000000001 1)
# 0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f
```

**SaferSafes module slot:**
```bash
cast keccak $(cast abi-encode 'f(address,uint256)' 0xA8447329e52F64AED2bFc9E7a2506F7D369f483a 1)
# 0x073d01777a7e5521317f64ce51f98946a042c5bdcaec99ecde1a1793ecae1afc
```

The linked list structure after this transaction:
```
SENTINEL (0x1) → SaferSafes (0xA844...) → SENTINEL (0x1)
```

### `0xA8447329e52F64AED2bFc9E7a2506F7D369f483a` (SaferSafes)

| Key | Before | After | Description |
|-----|--------|-------|-------------|
| `0x6052abafb2ff82960e0d771a47c27c4775165ed12acba1a270353154fbf7fe80` | `0x0` | `0x278d00` | `livenessSafeConfiguration[FoS].livenessResponsePeriod` = 2592000 (30 days) |
| `0x6052abafb2ff82960e0d771a47c27c4775165ed12acba1a270353154fbf7fe81` | `0x0` | `0x...c2819dc788505aac350142a7a707bf9d03e3bd03` | `livenessSafeConfiguration[FoS].fallbackOwner` = Security Council |

#### Slot Derivation

The SaferSafes contract stores liveness configuration in a mapping. The base slot for FoS's configuration is computed as:

```
baseSlot = keccak256(abi.encode(fosAddress, mappingSlot))
```

The `ModuleConfig` struct has two fields stored at consecutive slots:
- `livenessResponsePeriod` at `baseSlot + 0`
- `fallbackOwner` at `baseSlot + 1`

### Links

- [Gnosis Safe Module Manager](https://github.com/safe-global/safe-smart-account/blob/v1.4.1/contracts/base/ModuleManager.sol)
- [SaferSafes Contract](https://etherscan.io/address/0xA8447329e52F64AED2bFc9E7a2506F7D369f483a)
- [Foundation Operations Safe](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A)
- [Security Council](https://etherscan.io/address/0xc2819DC788505Aac350142A7A707BF9D03E3Bd03)
