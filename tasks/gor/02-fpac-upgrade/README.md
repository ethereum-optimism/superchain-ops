# Goerli FPAC Upgrade

## Objective

This is the playbook for executing the Fault Proof Alpha Chad upgrade on Goerli.

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

1. "Network": Check the network is Goerli (`5`).
2. "Timestamp": Check the simulation is performed on a block with a recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not, you will need to determine which “number” it is in the list of
   addresses on your ledger. By default the script will assume the derivation path is m/44'/60'/0'/0/0. By calling the script with
   `just simulate 1` it will derive the address using `m/44'/60'/1'/0/0` instead.
