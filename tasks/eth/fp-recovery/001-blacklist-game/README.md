# Deputy Guardian - Blacklist Dispute Game

Status: CONTINGENCY TASK, SIGN AS NEEDED

## Objective

This task executes a `blacklistDisputeGame` operation in the `OptimismPortalProxy` on behalf of the `Guardian` role. Blacklisting the dispute game prevents any withdrawals proven to be contained within the game's proposed output root from being finalized.

The batch will be executed on chain ID `1`, and contains `1` transaction.

## Tx #1: Blacklist Dispute Game

Executes the `blacklistDisputeGame` call to the `OptimismPortalProxy`.

**Function Signature:** `blacklistDisputeGame(address,address)`

**To:** `0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B`

**Value:** `0 WEI`

**Raw Input Data**

|Function Selector Signature| OptimismPortalProxyAddress (left-padded to 32 bytes) | DisputeGameToBlacklistAddress  (left-padded to 32 bytes)|
|--------------------------|--------------------------------------------|--------------------------------------------|
|0x629cdd49|000000000000000000000000`OptimismPortalProxyAddress`|000000000000000000000000`DisputeGameToBlacklistAddress`|

### Inputs

**\_portal:** `<user-input>`

**\_game:** `<user-input>`

## Preparing the Operation

1. Locate the address of the `OptimismPortalProxy` to blacklist a dispute game on. For OP Stack chains that support fault proofs, the contract address can be located in the respective `.toml` file in the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry/tree/2c96a89df841013a59269fa7adc12c77b870310e/superchain/configs/mainnet).

2. Locate the address of the dispute game that the `DeputyGuardianModule` wishes to blacklist.

3. Generate the batch with `just generate-input <OptimismPortalProxyAddress> <DisputeGameToBlacklist>`.

4. Set the `L2_CHAIN_NAME` configuration to the appropriate chain in the `.env` file. Applicable chain names can be found in the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry/tree/2c96a89df841013a59269fa7adc12c77b870310e/superchain/configs/mainnet).

5. Collect signatures and execute the action according to the instructions in [SINGLE.md](../../../../SINGLE.md).

### State Validations

The two state modifications that are made by this action are:

1. An update to the nonce (increment of `1`) of the `DeputyGuardianModule` safe.
2. An update to the storage slot within the `disputeGameBlacklist` mapping in the `OptimismPortalProxy`, which will be set to `1` for the corresponding `blacklistDisputeGame` address.

The state changes should look something like this:

![state-diff](./images/state_diff.png)

To check the validity of the slot that was changed on the `OptimismPortalProxy`, the `cast index` utility can be used to compute the storage slot
that will be used for the address being blacklisted in the `disputeGameBlacklist` mapping:

```sh
export PORTAL_BLACKLIST_MAP_SLOT="58"
export BLACKLISTED_ADDRESS="<blacklisted-address>"
cast index \
    address \
    $BLACKLISTED_ADDRESS \
    $PORTAL_BLACKLIST_MAP_SLOT
```

You can verify the expected `PORTAL_BLACKLIST_MAP_SLOT` in [`OptimismPortal` storage layout snapshot](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L93C1-L99C5)

