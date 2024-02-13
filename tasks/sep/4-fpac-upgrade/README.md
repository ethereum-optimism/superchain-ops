# Sepolia FPAC Upgrade

## Objective

This is the playbook for executing the Fault Proof Alpha Chad upgrade on Sepolia.

The Fault Proof Alpha Chad upgrade:

1. Deploys the FPAC System
   - [`MIPS.sol`][mips-sol]
   - [`PreimageOracle.sol`][preimage-sol]
   - [`FaultDisputeGame.sol`][fdg-sol]
   - [`PermissionedDisputeGame.sol`][soy-fdg-sol]
   - [`DisputeGameFactory.sol`][dgf-sol]
1. Upgrades the `OptimismPortal` proxy implementation to [`OptimismPortal2.sol`][portal-2]

[mips-sol]: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/cannon/MIPS.sol
[preimage-sol]: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/cannon/PreimageOracle.sol
[fdg-sol]: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol
[soy-fdg-sol]: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/dispute/PermissionedDisputeGame.sol
[dgf-sol]: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol
[portal-2]: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/src/L1/OptimismPortal2.sol

## Preparing the Upgrade

1. Cut a release of the `op-program` in the Optimism Monorepo to generate a reproducible build.

   - _Note_: This release pipeline is not yet available.

2. In the Optimism Monorepo, add the absolute prestate hash from the above release into the deploy config for the chain that is being upgraded.

3. Deploy the FPAC system to the settlement layer of the chain. The deploy script can be found in the Optimism Monorepo, under the `contracts-bedrocks` package.

```sh
cd packages/contracts-bedrock/scripts/fpac && \
   just deploy-fresh chain=<chain-name> proxy-admin=<chain-proxy-admin-addr> system-owner-safe=<chain-safe-addr> args="--broadcast"
```

4. Fill out `meta.json` with the deployed `OptimismPortal2` and `DisputeGameFactoryProxy` contracts from step 3.

5. Generate the `input.json` with `just generate-input`

## Approving the Transaction

### 1. Update repo and move to the appropriate folder for this rehearsal task:

```
cd superchain-ops
git pull
just install
cd tasks/gor/02-fpac-upgrade
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum application needs to be opened on Ledger with the message "Application is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

Remember that by default `just` is running with the address derived from `/0` (first nonce). If you wish to use a different account, run
`just simulate [X]`, where X is the derivation path of the address that you want to use.

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
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is Sepolia (`11155111`).
2. "Timestamp": Check the simulation is performed on a block with a recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not, you will need to determine which “number” it is in the list of
   addresses on your ledger. By default the script will assume the derivation path is m/44'/60'/0'/0/0. By calling the script with
   `just simulate 1` it will derive the address using `m/44'/60'/1'/0/0` instead.

#### 3.2. Validate correctness of the state diff and events.

_TODO_

#### 3.3. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Overview" tab, and find the `GnosisSafe.checkSignatures` call. This call's `data` parameter
contains both the domain hash and the message hash that will show up in your Ledger.

Here is an example screenshot. Note that the hash value may be different:

![](./images/tenderly-sim-check-sig.png)

Seb's sig data: `0x1901d0038af9d1425c8c3831ba8a43a136259ebe7d15ecb0ce60bd3b90f4189487641527ccc2d6f5fcacdd23c4a9a6fef57bcc6c969aa4f4819a86c2e4a5e14b7f26`

It will be a concatenation of `0x1901`, the domain hash, and the
message hash: `0x1901[domain hash][message hash]`.

Note down this value. You will need to compare it with the ones displayed on the Ledger screen at signing.

### 4. Approve the signature on your ledger

Once the validations are done, it's time to actually sign the transaction. Make sure your ledger is still unlocked and run the
following:

```shell
just sign # or just sign <hdPath>
```

> [!NOTE]
> This is the most security critical part of the playbook: make sure the domain hash and message hash in the
> following two places match:

1. on your Ledger screen.
2. in the Tenderly simulation. You should use the same Tenderly simulation as the one you used to verify the state diffs, instead
   of opening the new one printed in the console.

There is no need to verify anything printed in the console. There is
no need to open the new Tenderly simulation link either.

After verification, sign the transaction. You will see the `Data`, `Signer` and `Signature` printed in the console. Format should be
something like this:

```
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Double check the signer address is the right one.

### 5. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and congrats, you are done!

## [For Facilitator ONLY] How to execute the upgrade

### [After the signatures are collected] Execute the output

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export it as the `SIGNATURES` environment variable, i.e. `export SIGNATURES="0x[SIGNATURE1][SIGNATURE2]..."`.
3. Run `just execute 0 # or 1 or ...` to execute the transaction onchain.

For example, if the quorum is 2 and you get the following outputs:

```shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE01
Signature: AAAA
```

```shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE02
Signature: BBBB
```

Then you should run

```shell
export SIGNATURES="0xAAAABBBB"
just execute 0 # or 1 or ...
```
