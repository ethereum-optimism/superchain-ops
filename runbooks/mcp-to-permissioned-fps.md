# Upgrade runbook: op-contracts/v1.3.0 to op-contracts/v1.6.0

## Summary

This runbook describes the process necessary to upgrade a chain from `op-contracts/v1.3.0` [link](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.3.0) to `op-contracts/v1.6.0` [link](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.6.0). This is the fault proof system running with the **PermissionedDisputeGame** type. Additionally, this runbook will update your chain to point to the unified `SuperchainConfig` contract. A number of L2 upgrades are required before any contract changes can be made. Certain off-chain services are introduced or modified.

## IMPORTANT: SuperchainConfig update

This upgrade includes a change that will point the `SuperchainConfig` contract that your chain uses to the unified `SuperchainConfig` managed by the Optimism Foundation and the Optimism Security Council. The `SuperchainConfig` contract defines the `Guardian` role which in turn has the ability to execute certain safety-net actions on contracts using this `SuperchainConfig`.

### Guardian role

The `Guardian` role is held by the Optimism Security Council. The `Guardian` role has additionally been delegated by the Optimism Security Council to the Optimism Foundation to improve response time in case of an emergency. The Optimism Security Council can remove this delegation to the Optimism Foundation at any time.

### Permissions

The `Guardian` role can trigger the `pause` and `unpause` functions within the `SuperchainConfig` contract. When the `SuperchainConfig` is `paused`, contracts pointing at this `SuperchainConfig` will prevent users from executing certain functions. For instance, the `L1CrossDomainMessenger` will not allow `relayMessage` to be executed when `SuperchainConfig.paused() == true`.

The `Guardian` role **can ONLY impact the liveness** and not the **safety** of the system. This means that the `Guardian` can prevent users from executing withdrawals but the `Guardian` cannot execute an invalid or malicious withdrawal. The `Guardian` is designed to be used to prevent invalid withdrawals from being executed by other users.

**Guardian function permissions:**

- `SuperchainConfig.pause`
- `SuperchainConfig.unpause`
- `OptimismPortal.blacklistDisputeGame`
- `OptimismPortal.setRespectedGameType`
- `AnchorStateRegistry.setAnchorState`

## Upgrade to latest L2 software

You will need to update your L2 chain software (Sequencer and other nodes) to the latest governance approved software. Refer to the [Releases page](https://github.com/ethereum-optimism/optimism/releases) on the Optimism Monorepo to determine the latest OP Stack release that you should be using. Please contact OP Labs developer support if you are uncertain about the correct version to use.

## Review fee scalar

The [Fjord upgrade](https://gov.optimism.io/t/upgrade-proposal-9-fjord-network-upgrade/8236) modified the way in which batch data is compressed. We recommend confirming that your fee scalar values (set inside of the `SystemConfigProxy` contract) are accurate after upgrading to Fjord.

## Update chain configuration

You will need to update your deployment JSON file with the following new variables to be able to deploy the contracts for `op-contracts/v1.6.0`. Please read this section carefully to understand what each new configuration variable is used for. Send your updated deployment configuration to OP Labs for archival purposes.

| Variable                        | Value                                                                                                                                                                                     | Description                                                                                                                                                     |
|---------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| useFaultProofs                  | true                                                                                                                                                                                      | Ensures deployment script uses fault proofs contracts.                                                                                                          |
| faultGameMaxDepth               | 73                                                                                                                                                                                        | Maximum number of steps that can occur in any given dispute game.                                                                                               |
| faultGameSplitDepth             | 30                                                                                                                                                                                        | Game depth at which the dispute game transitions from bisecting over blocks to bisecting over execution steps within a given block.                             |
| faultGameWithdrawalDelay        | 604800                                                                                                                                                                                    | Number of seconds after the fault dispute game resolves before a user can withdraw bonds.                                                                       |
| faultGameMaxClockDuration       | 302400                                                                                                                                                                                    | Number of seconds each of the two teams gets when playing the dispute game.                                                                                     |
| faultGameClockExtension         | 10800                                                                                                                                                                                     | Number of seconds below which additional time is added to the game clock when a move is made.                                                                   |
| faultGameAbsolutePrestate       | 0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c                                                                                                                        | Absolute prestate for the instruction trace for the fault dispute game. See Notes for faultGameAbsolutePrestate.                                                |
| faultGameGenesisBlock           | 0                                                                                                                                                                                         | Block number of a recent finalized L2 block at the time of deployment. Set to 0 for permissioned deployments.                                                   |
| faultGameGenesisOutputRoot      | 0xdead000000000000000000000000000000000000000000000000000000000000                                                                                                                        | As this is a deployment for a permissioned system, the first output root can be set to any value as long as it is non-zero and clearly not a valid output root. |
| l2OutputOracleProposer          | Recommended to use the same proposer address that was previously used in op-contracts/v1.3.0. Note that the proposer is a hot wallet that should be securely maintained inside of an HSM. | Address that is allowed to propose and challenge dispute games within the permissioned dispute game contract.                                                   |
| l2OutputOracleChallenger        | Recommended to use the same challenger address that was previously used in op-contracts/v1.3.0.                                                                                           | Address that is allowed to challenge dispute games within the permissioned dispute game contract.                                                               |
| respectedGameType               | 1                                                                                                                                                                                         | Dispute game type to respect within the OptimismPortal contract. Using 1 indicates that the PermissionedDisputeGame will be respected.                          |
| preimageOracleMinProposalSize   | 126000                                                                                                                                                                                    | Minimum size in bytes that the large preimage challenge can be triggered.                                                                                       |
| preimageOracleChallengePeriod   | 86400                                                                                                                                                                                     | Challenge period in seconds for the large preimage challenge process.                                                                                           |
| proofMaturityDelaySeconds       | 604800                                                                                                                                                                                    | Number of seconds that must elapse before a withdrawal proof can be used to finalize a withdrawal. See Notes for proofMaturityDelaySeconds.                     |
| disputeGameFinalityDelaySeconds | 302400                                                                                                                                                                                    | Number of seconds that must elapse after a dispute game is finalized before it can be used to finalize a withdrawal.                                            |

Below is a duplicate of the above information that can be copy/pasted into your JSON configuration file. Note that you must still manually modify `l2OutputOracleProposer` and `l2OutputOracleChallenger` if you intend to change those addresses (not required).

```json
  "useFaultProofs": true,
  "faultGameMaxDepth": 73,
  "faultGameSplitDepth": 30,
  "faultGameWithdrawalDelay": 604800,
  "faultGameMaxClockDuration": 302400,
  "faultGameClockExtension": 10800,
  "faultGameAbsolutePrestate": "0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c",
  "faultGameGenesisBlock": 0,
  "faultGameGenesisOutputRoot": "0xdead000000000000000000000000000000000000000000000000000000000000",
  "respectedGameType": 1,
  "preimageOracleMinProposalSize": 126000,
  "preimageOracleChallengePeriod": 86400,
  "proofMaturityDelaySeconds": 604800,
  "disputeGameFinalityDelaySeconds": 302400
```

## Notes for Selected Variables

**Notes for `faultGameAbsolutePrestate`**

`faultGameAbsolutePrestate` is being set to the standard prestate. Because your chain will be a *permissioned* system, this prestate will NOT be valid and therefore will prevent the `op-challenger` from being able to successfully challenge a faulty output root proposal. Setting the prestate to this value WILL allow the `op-challenger` to properly *resolve* dispute games on behalf of the `proposer`.

Since you will be operating under a permissioned proof system, this has no effect unless the `proposer` wallet is compromised. If the `proposer` wallet is compromised, monitoring will detect the malicious proposal and the `DeputyGuardian` account can temporarily disable the proof system until a functioning `proposer` is instated.

**Notes for `proofMaturityDelaySeconds`**

Worth noting that this is set to 7 days on both testnet and mainnet to maintain a consistent experience between both networks. Although not strictly necessary for a permissioned setup, a delay is necessary for a permissionless setup (on both testnet and mainnet). We recommend keeping this value at 7 days on both networks.

**Notes for `disputeGameFinalityDelaySeconds`**

Similar to `proofMaturityDelaySeconds`, this is set to 3.5 days for both testnet and mainnet. We recommend keeping this value at 3.5 days on both networks.

## Upgrade Deployment

The upgrade from `op-contracts/v1.3.0` to `op-contracts/v1.6.0` is designed to be carried out by a docker image to maintain a consistent environment across deployments.

**Deployment deployment summary**

Upgrade begins by deploying and configuring a number of new smart contracts that your system will need to upgrade to `op-contracts/v1.6.0`. Docker image will produce an output file called `deploy.log` containing a log of everything that happened during the deployment and a file called `deployments.json` that lists the newly created contract addresses.

**Deployment details:**

1. Deploys `DisputeGameFactory` proxy contract
2. Deploys `AnchorStateRegistry` proxy contract
3. Deploys `DelayedWETH` proxy contract for permissioned proofs
4. Deploys `AnchorStateRegistry` implementation contract
5. Initializes `DisputeGameFactory` proxy contract
6. Initializes `AnchorStateRegistry` proxy contract
7. Initializes `DelayedWETH` proxy contract for permissioned proofs
8. Deploys `PermissionedDisputeGame` contract and sets it as game type 1
9. Transfers ownership of `DelayedWETH` proxy (permissioned) to `ProxyAdmin`
10. Transfers ownership of `DisputeGameFactory` proxy to `ProxyAdmin`
11. Transfers ownership of `AnchorStateRegistry` to system owner

**Finalization transaction generation**

Once contracts have been deployed, the docker image will generate a JSON file called `bundle.json` containing transactions that are compatible with the Transaction Builder feature for the Safe smart wallet. Your system will using `op-contracts/v1.6.0` contracts once this bundle is executed. You should ONLY execute this bundle once you are ready to transition your system to `op-contracts/v1.6.0`.

**Upgrade details:**

1. Upgrades `OptimismPortalProxy` to `StorageSetterImpl`
2. Resets `initialized` variable inside of `OptimismPortalProxy`
3. Resets `l2Sender` variable inside of `OptimismPortalProxy`
4. Upgrades `OptimismPortalProxy` to `OptimismPortal2Impl`
5. Initializes `OptimismPortalProxy`
6. Upgrades `SystemConfigProxy` to `StorageSetterImpl`
7. Clears the `keccak(systemconfig.l2outputoracle)-1` slot
8. Sets the `keccak(systemconfig.disputegamefactory)-1` slot
9. Resets `initialized` variable inside of `SystemConfigProxy`
10. Upgrades `SystemConfigProxy` to `SystemConfigImpl`
11. Initializes `SystemConfigProxy`
12. Upgrades `L1CrossDomainMessengerProxy` to `StorageSetterImpl`
13. Resets `initialized` variable inside of `L1CrossDomainMessengerProxy`
14. Upgrades `L1CrossDomainMessengerProxy` to `L1CrossDomainMessengerImpl`
15. Initializes `L1CrossDomainMessengerProxy`
16. Upgrades `L1StandardBridgeProxy` to `StorageSetterImpl`
17. Resets `initialized` variable inside of `L1StandardBridgeProxy`
18. Upgrades `L1StandardBridgeProxy` to `L1StandardBridgeImpl`
19. Initializes `L1StandardBridgeProxy`
20. Upgrades `L1ERC721BridgeProxy` to `StorageSetterImpl`
21. Resets `initialized` variable inside of `L1ERC721BridgeProxy`
22. Upgrades `L1ERC721BridgeProxy` to `L1ERC721BridgeImpl`
23. Initializes `L1ERC721BridgeProxy`
24. Upgrades `OptimismMintableERC20Factory` to `OptimismMintableERC20FactoryImpl`

**Validation text generation**

After generating the finalization transaction, the docker image will generate a file named `validation.txt` that can be used to verify that the upgrade transaction is correctly changing the state of your system. This file is designed to be used alongside a Tenderly simulation of the finalization transaction bundle to manually verify the state changes shown in the Tenderly UI.

**Outputs**

- `deploy.log` is a full log of the execution of the deploy script
- `bundle.json` is the finalization transaction bundle
- `validation.txt` is used to verify the state diffs of the upgrade transaction
- `deployments.json` is the list of addresses deployed
- `standard-addresses.json` is the list of standard implementation addresses used
- `transactions.json` is the list of transactions that were executed

**Deployment cost**

We recommend providing the deployer account with 1 ETH on Mainnet and 10 ETH on Sepolia to minimize the chance of a failed deployment. Actual deployment cost should be significantly less than these recommended values.

- Estimated Gas: `12,000,000`
- Mainnet Cost: `~0.15 ETH @ ~13gwei`
- Sepolia Cost: `~3 ETH @ ~250gwei`

## Executing the deployment

1. Create a working directory
    
    ```bash
    mkdir upgrade-dir
    cd upgrade-dir
    ```
    
2. Copy your deploy config and deployment addresses JSON files into the working directory
    
    > [!IMPORTANT]
    > Please make sure that your deploy config JSON is in the standard config format used by the official OP Stack deployment script and includes all required configuration values as of `op-contracts/v1.3.0`.
    
3. Make sure that your files are named correctly, deploy config should be named `deploy_config.json` your deployment addresses file should be named `deployments.json`
    
    > [!NOTE]
    > Standardized file names reduce the chance of errors when running this runbook.
        
4. Create a folder called `outputs`
    
    ```bash
    mkdir outputs
    ```
    
5. Create a file called `.env`
        
    ```bash
    touch .env
    ```

6. Add the following to `.env` and fill out all required variables
    
    ```bash
    ##############################################
    #               ↓  Required  ↓               #
    ##############################################

    # Can be "mainnet" or "sepolia"
    NETWORK=

    # Etherscan API key used to verify contract bytecode
    ETHERSCAN_API_KEY=

    # RPC URL for the L1 network that matches $NETWORK
    ETH_RPC_URL=

    # Private key used to deploy the new contracts for this upgrade
    PRIVATE_KEY=

    # Check if required files and folders exist
    if [ ! -f "./deploy_config.json" ]; then
        echo "Error: deploy_config.json not found"
    fi
    if [ ! -f "./deployments.json" ]; then
        echo "Error: deployments.json not found"
    fi
    if [ ! -d "./outputs" ]; then
        echo "Error: outputs folder not found"
    fi
    ```
    
7. Load the `.env` file into your environment
    
    If you get an error when running this command, make sure that your input files are properly named and that you have created the `outputs` folder.

    ```bash
    source .env
    ```
    
8. Run the deployment process
    
    ```bash
    docker run -t \
        --env-file .env \
        -v ./deploy_config:/deploy_config.json \
        -v ./deployments.json:/deployments.json \
        -v ./outputs:/outputs \
        kfoplabs/upgrade-v1.3.0-v1.6.0-permissioned:latest \
        /deploy_config.json \
        /deployments.json
    ```
    
9. Wait for the process to complete and look for outputs inside of the `outputs` folder
    

    > [!IMPORTANT]
    > Deployment scripts can fail if your RPC has intermittent errors. Provided docker image does not handle these errors. You can safely re-execute the deployment script if the deployment fails.

10.   **SAVE** the generated deployment artifacts
    
      - `deploy.log` is a log of the deployment process
      - `deployments.json` includes the newly deployed contract addresses
      - `bundle.json` is the finalization transaction bundle
      - `validation.txt` is used for Tenderly state diff validation

## Simulate finalization transaction

Before running the `op-proposer` and `op-challenger`, it is recommended to simulate and validate the upgrade finalization transaction. The `bundle.json` file that you generated in the previous step contains an transaction bundle that is compatible with the Safe web application’s Transaction Builder feature. You can use this feature alongside `validation.txt` to verify the correctness of `bundle.json`.

**Creating a Tenderly Simulation**

1. Open the Safe web app (app.safe.global)
    
    > [!NOTE]
    > The Safe web app may not be able to import these JSON files on Firefox. Chrome and other Chromium-based browsers appear to function correctly.
    
2. Open the relevant Safe smart wallet
3. Click the `New transaction` button
4. Choose `Transaction Builder`
5. Look for `Drag and drop a JSON file or choose a file` and click `choose a file`
6. Open `bundle.json`
    
    > [!NOTE]
    > You may see a warning when opening this file that says something along the lines of “This batch contains some changed properties since you saved or downloaded it”. You can safely ignore this warning.
    
7. Click `Create Batch`
8. Click `Simulate`
9. Find and open the link to the generated Tenderly simulation
10. In Tenderly, navigate to the `State` tab
11. Compare the changes in the `State` tab to the contents of `validation.txt`
12. Do **NOT** execute the bundle in the Safe app yet

**Using the validation file**

`validation.txt` contains a list of state changes that you should observe when executing your transaction bundle. It has been designed to mirror the structure of the `State` tab in Tenderly. For each state change in the Tenderly State tab, make sure that the change is also present inside of `validation.txt`. ALL changes inside of the `State` tab should be present inside of the `validation.txt` file EXCEPT for changes to account nonces. Please notify OP Labs if you see any other state changes inside of the `State` tab that are not present in `validation.txt`.

## Running a proposer and challenger

You can safely run an instance of `op-proposer` and `op-challenger` after you’ve deployed the contracts for the `op-contracts/v1.6.0` upgrade and validated the upgrade bundle. It is not necessary to shut down your existing `op-proposer` instance. Once the upgrade finalization transaction is executed, the system will seamlessly transition from the `op-contracts/v1.3.0` contracts to the `op-contracts/v1.6.0` contracts.

**Running a proposer**

Refer to the [Releases page](https://github.com/ethereum-optimism/optimism/releases) on the Optimism Monorepo to determine the latest OP Stack release that you should be using.

`op-proposer` has already been updated to support `op-contracts/v1.6.0` if you are using the latest governance-approved version of the OP Stack. You can safely run an instance of `op-proposer` for `op-contracts/v1.6.0` in parallel with your current production instance.

**Configuration**

You can generally use the same configuration that you currently use for `op-proposer` with the following modifications:

- `L2OOAddressFlag`
    - `--l2oo-address, L2OO_ADDRESS`
    - Must be empty
- `DisputeGameFactoryAddressFlag`
    - `--game-factory-address, GAME_FACTORY_ADDRESS`
    - Must be set to the address of the `DisputeGameFactoryProxy` contract
- `DisputeGameTypeFlag`
    - `--game-type, GAME_TYPE`
    - Must be set to `1`
- `ProposalIntervalFlag`
    - `--proposal-interval, PROPOSAL_INTERVAL`
    - Recommend setting this to `1h`

**Running a challenger**

Refer to the [Releases page](https://github.com/ethereum-optimism/optimism/releases) on the Optimism Monorepo to determine the latest OP Stack release that you should be using.

> [!NOTE]
> `op-challenger` v1.1.2 modified the `op-challenger` to disable prestate checks for the permissioned game. This change ensures that the `op-challenger` will correctly resolve games regardless of the configured prestate value.

`op-challenger` is a service that participates in the dispute game process and challenges invalid proposals. The `op-challenger` will NOT have permission to post counterclaims in the permissioned games as the EOA account it uses is not the CHALLENGER role. Under this permissioned setup, the `op-challenger` primarily serves to resolve dispute games on behalf of the proposer and can act as additional monitoring. Refer to [the Optimism Developer Docs](https://docs.optimism.io/builders/chain-operators/tools/op-challenger) for a detailed overview of how to run the `op-challenger`.

**Configuration**

For networks not in the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/chainList.json) you need: 

- `CannonRollupConfigFlag`
    - `cannon-rollup-config, CANNON_ROLLUP_CONFIG`
    - Rollup chain parameters (cannon trace type only)
- `CannonL2GenesisFlag`
    - `cannon-l2-genesis, CANNON_L2_GENESIS`
    - Path to the `op-geth` genesis file (cannon trace type only)
- `CannonPreStateFlag`
    - `cannon-prestate, CANNON_PRESTATE`
    - Path to absolute prestate to use when generating trace data (cannon trace type only)
    - **Important details**
        - Must be `0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c`. This is the same value as OP Mainnet because it should correspond to the latest version of the `op-program`. This version of the op-program doesn’t account for chains recently added or not in the `superchan-registry`, but for permissioned games that is fine because it will never actually execute.
        - The simplest option for the permissioned game, given it won’t be used for execution, is to specify a static file and omit the `CANNON_PRESTATES_URL` option.  The local file doesn’t even need to exist.
            - The `PRESTATES_URL` version is needed when moving to the permissionless game so that the challenger can download the particular prestate that matches the dispute game it needs to act on (games may have different prestates because of upgrades). When using the URL version challenger needs to find a file to download from the URL even for the permissioned game.

## Running a dispute monitor

Refer to the [Releases page](https://github.com/ethereum-optimism/optimism/releases) on the Optimism Monorepo to determine the latest OP Stack release that you should be using.

`op-dispute-mon` is a service that monitors the status of the dispute games created by the `DisputeGameFactory`. `op-dispute-mon` is the primary monitoring tool that chain operators can use to verify that dispute games are resolving correctly. Refer to the `op-dispute-mon` [README](https://github.com/ethereum-optimism/optimism/blob/develop/op-dispute-mon/README.md) for a basic overview of the service.

**Configuration**

You will need to set the following flags for `op-dispute-mon` at a minimum:

- `L1EthRpcFlag`
    - `--l1-eth-rpc, L1_ETH_RPC`
    - RPC URL for a reliable and trusted L1 node
- `RollupRpcFlag`
    - `--rollup-rpc, ROLLUP_RPC`
    - RPC URL for a reliable and trusted L2 rollup node (`op-node`)
- `GameFactoryAddressFlag`
    - `--game-factory-address, GAME_FACTORY_ADDRESS`
    - Address of the `DisputeGameFactoryProxy`
- `HonestActorsFlag`
    - `--honest-actors, HONEST_ACTORS_FLAG`
    - Ensure that the address of the `Proposer` is included in this list

## Executing the finalization transaction

> [!IMPORTANT]
> Transaction bundles **MUST** be executed atomically within a single transaction. Do NOT execute each transaction within the bundle individually. Executing the bundle non-atomically is UNSAFE and can open the system up to critical vulnerabilities.

You should have generated a JSON file called `bundle.json` when you deployed the required contracts. `bundle.json` contains a list of transactions compatible with the Transaction Builder feature for the Safe smart wallet. Once you execute this transaction bundle, your chain will be running the `op-contracts/v1.6.0` system. You should make sure that you are successfully able to run the services described above before executing this transaction bundle.

## Updating the superchain-registry

If your chain is in the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry/tree/main), make sure to open a PR to update the chain information.
