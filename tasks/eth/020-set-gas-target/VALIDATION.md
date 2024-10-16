## Validations
For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

* The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
* All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` GnosisSafe for SystemConfigOwner: 

* Key: `0x0000000000000000000000000000000000000000000000000000000000000004`
* Value: `0x0000000000000000000000000000000000000000000000000000000000000001`

### State Changes

#### `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` SystemConfigProxy

* Key: `0x0000000000000000000000000000000000000000000000000000000000000068`
* Before: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
* After: `0x0000000000000000000000000000000000000000000000000000000003938700`
* Meaning: updates `gasLimit` from `30_000_000` to `60_000_000`

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` GnosisSafe for SystemConfigOwner

* Key: `0x0000000000000000000000000000000000000000000000000000000000000005`
* Before: `0x0000000000000000000000000000000000000000000000000000000000000009`
* After: `0x000000000000000000000000000000000000000000000000000000000000000a`
* Meaning: updates `nonce` from `9` to `10`

#### `0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64` tx sender

* Key: `nonce`
* Before: `1`
* After: `2`
* Meaning: updates `nonce` from `1` to `2`


![](./images/state.png)

### Events

#### `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` SystemConfigProxy

* ConfigUpdate: data is the encoded new gas limit (`0x3938700` = `60_000_000`)

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` GnosisSafe for SystemConfigOwner

* ExecutionSuccess


![](./images/events.png)