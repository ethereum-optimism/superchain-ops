# Superchain Presigned Pause

Status: READY TO SIGN

## Instructions

Begin by setting the `SCRIPT` env var with the following command:

```
export SCRIPT=PresignPauseFromJson_eth_017
```

Then see [../../../PRESIGNED-PAUSE.md](../../../PRESIGNED-PAUSE.md) for the remainder of the
playbook.

## Additional Overrides

In order to enable the transaction simulation, prior to execution of the Guardian and Security
Council upgrades, this playbook requires additional overrides beyond what are typically included in
a presigned pause playbook.

The following is an explanation of those overrides. All other validation steps should be contained
in the PRESIGNED_PAUSE.md playbook linked to above.

### `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2` (1/1 Guardian Safe)

Links:
- [Etherscan](https://etherscan.io/address/0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2).

The following two changes are both updates to the `modules` mapping, which is in [slot 1](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L10).

**Key:** `0x122c127b258a6e22748d3f3c38ae3a4c32252b46d3ad49e5d85acb3626c15d39` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The `DeputyGuardianModule` at [`0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B`](https://etherscan.io/address/0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B) is now pointing to the sentinel module at `0x01`.
  This is `modules[0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B]`, so the key can be
    derived from `cast index address 0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B 1`.

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x000000000000000000000000c6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B` <br/>
**Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyGuardianModule` at [`0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B`](https://etherscan.io/address/0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.


### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (Foundation Operations Safe)

The Safe will have the following overrides to set your address as the sole owner of the signing safe, to allow simulating the tx in Tenderly.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000005 <br/>
  **Value:** 0x000000000000000000000000000000000000000000000000000000000000005F <br/>
  **Meaning:** This is the nonce override. You will not see it when signing the first nonce (as it matches to the current nonce). In subsequent simulations the value will be in the range from 0x5d to 0x60. This is set to 95 (0x5F) because that's what task 019 will use.
