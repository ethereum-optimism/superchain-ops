# Rehearsal 4 - Protocol Upgrade via Nested Multisig

## Objective

In this rehearsal we will be performing a protocol upgrade of the
Superchain.

Once Completed:
1. The L1ERC721BridgeProxy contract will be upgraded to a new
   implementation.
2. The OptimismPortalProxy contract will be upgraded to a new
   implementation and reinitialized.

The call that will be executed by the Safe contract is defined in a
json file. This will be the standard approach for all transactions.

Note that no onchain actions will be taking place during this
signing. You won’t be submitting a transaction and your address
doesn’t even need to be funded. These are offchain signatures produced
with your wallet which will be collected by a Facilitator, who will
submit all signatures and perform the execution onchain.


## Approving the transaction

### 1. Update repo and move to the appropriate folder for this rehearsal task:

```
cd superchain-ops
git pull
just install
cd security-council-rehearsals/2024-02-03-r4-jointly-upgrade-0203
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

Remember that by default just is running with the address derived from
`/0` (first nonce). If you wish to use a different account, run `just
simulate-council [X]`, where X is the derivation path of the address
that you want to use.

``` shell
just simulate-council
```

You will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 3 validations and extract the domain hash and
message hash to approve on your Ledger:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.

#### 3.1. Validate integrity of the simulation.

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to

1. "Network": Check the network is Ethereum Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not,
   you will need to determine which “number” it is in the list of
   addresses on your ledger. By default the script will assume the
   derivation path is m/44'/60'/0'/0/0. By calling the script with
   `just simulate-council 1` it will derive the address using
   m/44'/60'/1'/0/0 instead.

![](./images/tenderly-overview-network.png)

#### 3.2. Validate correctness of the state diff.

Now click on the "State" tab. Verify that:

1. In `0x2D92E47419403204afE585A29A9E47A843227c71` (the
   `OptimismPortalProxy` contract):
   1. The implementation (storage key is the same as above) is changed
      to `0x0A9d47e531825FaaA2863D4d10DC8E5E0B91BfB0` ([source
      code](https://github.com/ethereum-optimism/optimism/blob/716f81a6fc4ef125364b95a799474082ea3eb062/packages/contracts-bedrock/src/L1/OptimismPortal.sol)).
   2. storage slot `0x0` (`_initialized`) is set to `0x2`.
   3. storage slot `0x1` (`ResourceParams`) set to
      `0x000000000117814800000000000000000000000000000000000000003b9aca00`,
      which means `prevBlockNum` is set to `0x1178148` or larger since
      the initialization logic always read the latest block number at
      init time, `prevBoughtGas` is set to 0, and `prevBaseFee` is set
      to `0x3b9aca00`.
   4. storage slot `0x32` (`l2Sender`) set to `0xdead`.
   5. storage slot `0x35` (Packed `l2Oracle` and `paused`) set to
      `0xdfe97868233d1aa22e815a266982f2cf17685a2700`, which means
      `l2Oracle` is set to
      [`0xdfe97868233d1aa22e815a266982f2cf17685a27`](https://etherscan.io/address/0xdfe97868233d1aa22e815a266982f2cf17685a27#readProxyContract)
      and `paused` is set to false.
   6. storage slot `0x36` (`systemConfig`) set to
      [`0x229047fed2591dbec1ef1118d64f7af3db9eb290`](https://etherscan.io/address/0x229047fed2591dbec1ef1118d64f7af3db9eb290#readProxyContract).
   7. storage slot `0x37` (`guardian`) set to
      [`0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`](https://app.safe.global/settings/setup?safe=eth:0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A).

![](./images/tenderly-state-diff.png)


2. In `0x321938C3AD93F12Ff0001FA3ad8903A1f5FE9808` (the
   `L1ERC721BridgeProxy` contract):
   1. The implementation of the `L1ERC721BridgeProxy` contract
      (storage key
      [0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc](https://github.com/ethereum-optimism/optimism/blob/cb42a6108d780451f6cecceff8182e11aa6a0490/packages/contracts-bedrock/src/libraries/Constants.sol#L27C9-L27C75))
      is changed to `0x3311aC7F72bb4108d9f4D5d50E7623B1498A9eC0`.

All of these addresses should be part of the Optimism Governance vote
that approves this upgrade if this is a [Normal
Operation](https://github.com/ethereum-optimism/OPerating-manual/blob/1f42a3766d084864a818b93ce7ba0857a4a846ea/Security%20Council%20Charter%20v0.1.md#normal-operation).

![](./images/tenderly-state-implementation.png)


#### 3.3. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right
operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Overview" tab, and find the first
`GnosisSafe.domainSeparator` call. This call's return value will be
the domain hash that will show up in your Ledger.

Here is an example screenshot. Note that the hash value may be
different:

![](./images/tenderly-hashes-1.png)

Right before the `GnosisSafe.domainSeparator` call, you will see a
call to `GnosisSafe.encodeTransactionData`. Its return value will be a
concatenation of `0x1901`, the domain hash, and the message hash:
`0x1901[domain hash][message hash]`.

Here is an example screenshot. Note that the hash value may be
different:

![](./images/tenderly-hashes-2.png)

Note down both the domain hash and the message hash. You will need to
compare them with the ones displayed on the Ledger screen at signing.

### 4. Approve the signature on your ledger

Once the validations are done, it's time to actually sign the
transaction. Make sure your ledger is still unlocked and run the
following:

``` shell
just sign-council # or just sign-council <hdPath>
```

> [!IMPORTANT] This is the most security critical part of the
> playbook: make sure the domain hash and message hash in the
> following two places match:

1. on your Ledger screen.
2. in the Tenderly simulation. You should use the same Tenderly
   simulation as the one you used to verify the state diffs, instead
   of opening the new one printed in the console.

There is no need to verify anything printed in the console. There is
no need to open the new Tenderly simulation link either.

After verification, sign the transaction. You will see the `Data`,
`Signer` and `Signature` printed in the console. Format should be
something like this:

```
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Double check the signer address is the right one.

### 5. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which
will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a
Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and
congrats, you are done!

## [For Facilitator ONLY] How to prepare and execute the rehearsal

### [Before the rehearsal] Prepare the rehearsal

#### 1. Create the Council Safe

In [Phase
0](https://gov.optimism.io/t/intro-to-optimisms-security-council/6885)
of the Superchain's Security Council, OP Mainnet's upgrade key is
going to be shared between the Optimism Foundation and the Security
Council using a nested 2-of-2 multisig. To simulate that, we need to
create another Safe where the Council Safe is one of its owners. You
should leverage the [Safe
UI](https://app.safe.global/new-safe/create?chain=eth) to do that.

To make the prepartion and coordination of the ceremonies easier, we
recommend setting the threshold of the new multisig to 1, and add an
additional key controled by the Facilitator as the second owner.

#### 2. Create the rehearsal contracts

1. Set the `OWNER_SAFE` address in `.env` to the newly-created Safe
   address.
2. Set the `COUNCIL_SAFE` address in `.env` to the same one used in
   previous rehearsals.
2. Make sure your Ledger is connected and run `just deploy-contracts`
   to deploy the rehearsal contract. There will be three contracts
   deployed: the `L1ERC721BridgeProxy`, the `OptimismPortalProxy` and
   the `ProxyAdmin` as their admin.
3. Update the `L1ERC721BridgeProxy_ADDRESS`, the
   `OptimismPortalProxy_ADDRESS` and the `ProxyAdmin_ADDRESS`
   variables in `.env` to the newly-created contracts' addresses.

#### 3. Update input.json

1. Make sure the variables in the `.env` file have been updated, then
   run `just prepare-json` to update the `input.json` file.
2. Test the newly created rehearsal by following the security council
   steps in the `Approving the transaction` section above.
3. Update the rehearsal folder name in the `1. Update repo and move to
   the appropriate folder for this rehearsal task` section and the
   address in the `3.2. Validate correctness of the state diff`
   section above.
4. Commit the newly created files to Github.

### [After the rehearsal] Execute the output

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
   SIGNATURES="0x[SIGNATURE1][SIGNATURE2]..."`.
3. Run `just approve-council 0 # or 1 or ...` to execute a transaction
   onchain to approve the upgrade transaction.
4. Run `just execute-all 0 # or 1 or...` to execute the actual upgrade
   transaction.

For example, if the quorum is 2 and you get the following outputs:

``` shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE01
Signature: AAAA
```

``` shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE02
Signature: BBBB
```

Then you should run

``` shell
export SIGNATURES="0xAAAABBBB"
just execute 0 # or 1 or ...
```
