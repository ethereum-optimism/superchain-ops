# Key Handover Runbook

This document describes how to generate upgrade playbooks to upgrade chains from `op-contracts/v1.3.0` (MCP) to `op-contracts/v1.X.0` (Fault Proofs).

## Upgrades Involved

This runbook will apply the following upgrade:

- [Fault Proofs](#fault-proofs-upgrade-7)

Each upgrade is described below.
The Extended Pause upgrade is only applied to chains currently on the Bedrock commit, corresponding to the [`op-contracts/v1.0.0`](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.0.0) tag in the [Optimism monorepo](https://github.com/ethereum-optimism/optimism).

In either case, the upgrade will be a single, atomic transaction.

### Fault Proofs (Upgrade #7)

This protocol upgrade reduces the trust assumptions for users of OP Mainnet 
[and the OP Stack] by enabling permissionless output proposals and a 
permissionless fault proof system. As part of a responsible and safe rollout
of Fault Proofs, it preserves the ability for the guardian to override if 
necessary to maintain security. As a result, withdrawals no longer depend on 
the privileged proposer role posting an output root, allowing the entire 
withdrawal process to be completed without any privileged actions. The trust 
assumption is reduced to requiring only that the guardian role does not act 
to intervene.

Learn more:

- [Faul Proofs release notes](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts/v1.4.0). (This is release `op-contracts/v1.4.0`).
- [Governance post](https://gov.optimism.io/t/final-protocol-upgrade-7-fault-proofs/8161).
- [Blog post](https://blog.oplabs.co/https://blog.oplabs.co/the-fault-proof-system-is-available-for-the-op-stack/).

### Additional Context

One of the requirement for getting to Stage, 1 as defined by [L2Beat](https://medium.com/l2beat/introducing-stages-a-framework-to-evaluate-rollups-maturity-d290bb22befe)
is having a, "the implementation of a fully functional proof system, 
decentralization of [fault] proof submission."

> [!IMPORTANT]
> In addition to the L1 smart contracts, chain operators must be running [op-challeger](https://docs.optimism.io/builders/chain-operators/tools/op-challenger) to defend the chain against invalid L2 state root proposals and have [monitoring](https://github.com/ethereum-optimism/monitorism/tree/main) in place.

## Upgrade Process

### Setup

#### **Local Machine**

First, let’s make sure you have all the right repos and tools on your machine. Start by cloning the repos below and checking out the latest main branch unless stated otherwise. Then, follow the repo setup instructions for each.

1. https://github.com/ethereum-optimism/optimism
   1. Checkout the contract release tag `git checkout op-contracts/v1.4.0`
   2. Run `pnpm clean && pnpm install && cd packages/contracts-bedrock && pnpm build:go-ffi && forge build`
2. https://github.com/ethereum-optimism/superchain-ops
    1. Follow the installation instructions in the README: https://github.com/ethereum-optimism/superchain-ops?tab=readme-ov-file#installation
    2. Then, run `just install`.
3. https://github.com/ethereum-optimism/superchain-registry
    1. No setup steps.
4. https://github.com/clabby/msup
    1. Then, run `cargo build`. 
5. Ensure you have a Tenderly account.

#### Familiarize yourself with the `single.just` file (superchain-ops repo)

There are three just recipes in this file:

- `simulate` - to simulate the transactions in the the `input.json` bundle
- `sign` - to sign the transactions in the `input.json` bundle
- `execute` - to execute the transactions in the `input.json` bundle

We use `single.just` because the ProxyAdmin owners are regular Safe’s. (For OP Mainnet we use `nested.just` because the ProxyAdmin owner is a Safe, where both owners are also Safes).

### Scaffold the ops task (playbook) for your upgrade (superchain-ops repo)

#### Create a task directory in superchain-ops

```bash
mkdir tasks/<NETWORK_DIR>/<RUNBOOK_DIR>
```

In the superchain-ops repo, tasks live in `tasks/<NETWORK_DIR>/<RUNBOOK_DIR>` where:

- `NETWORK_DIR` is `eth` for Ethereum mainnet and `sep` for Sepolia.
- `RUNBOOK_DIR` is of the form `{chainName}-{upgradeIndex}-{upgradeName}`.
    - `chainName` is just the chain’s name i.e. `base` . This is excluded for OP Chains.
    - `upgradeIndex` starts at `001` for the first playbook and increments each time. This gives a sequential ordering to upgrade transactions occurring on that chain.
    - `upgradeName` is `fp-upgrade`

We'll use the `tasks/sep/mode-001-fp-upgrade` directory as our template.
Start by copying everything over:

```bash
cd tasks/{NetworkDir}

# copy everything from the mode directory into a directory that
# will be created.
cp -R mode-001-fp-upgrade/. {chainName}-001-fp-upgrade

# Delete the input.json file.
cd {chainName}-001-fp-upgrade
rm input.json

# Clean your environment to avoid forge caching issues.
forge clean
```

The `.env` file should look like below. t can be left alone, unless you need 
to change the address of the owner safe. This can be found with `cast call $ProxyAdmin "owner()(address)" -r $SEPOLIA_RPC_URL`,
and the proxy admin address can be found from the superchain registry. In 
other words, the `OWNER_SAFE` corresponds to the proxy admin owner. It’s 
populated with a default value as a result of the `cp` command ran above. 
This account might not actually be the correct proxy admin owner for the 
chain being upgraded, so you should *always* run that `cast` command to 
verify what address should be there.

```bash
ETH_RPC_URL=https://1rpc.io/sepolia # L1 Sepolia RPC URL that has archive data access.
OWNER_SAFE=0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD
SAFE_NONCE=""
```

### Deploy new proxies and implementations (todo)

The chain operator will need deployed the following proxies and implementation 
contracts. After they've completed that, they'll need to share those contract 
addresses.

New proxy addresses we need:

todo: update versions and add links

- DisputeGameFactoryProxy
- AnchorStateRegistryProxy
- DelayedWETHProxy

New implementation addresses we need:

- OptimismPortal2: [3.10.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol#L144)
- SystemConfig: [2.2.0](https://github.com/ethereum-optimism/optimism/blob/547ea72d9849e13ce169fd31df0f9197651b3f86/packages/contracts-bedrock/src/L1/SystemConfig.sol#L111)
- DisputeGameFactory: [1.0.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L25)
- FaultDisputeGame: [1.2.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol#L73)
- PermissionedDisputeGame: [1.2.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/PermissionedDisputeGame.sol)
- DelayedWETH: [1.0.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/weth/DelayedWETH.sol#L25)
- AnchorStateRegistry: [1.0.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L28)
- MIPS: [1.0.1](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/cannon/MIPS.sol#L47)
- PreimageOracle: [1.0.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/cannon/PreimageOracle.sol#L33)

#### Deploy the Contracts

todo: we'll likely reuse the OP Stack manager work here

### Generate the `input.json` (todo)

This transaction bundle will consist of seven transactions. Before you open up
the CLI, you should gather all the necessary inputs.

#### Tx #1. Upgrade OptimismPortal to StorageSetter

- **Name:** Upgrade OptimismPortal to StorageSetter
- **Description:** Upgrade OptimismPortal to StorageSetter and reset `initializing`
- **To:** {L1 Proxy Admin Address}
- **Value:** 0
- **Function Signature:** upgradeAndCall(address,address,bytes)
- **Raw Input Data:** 

To generate the raw input data, use the following command:

```bash
cast calldata upgradeAndCall(address,address,bytes) {_proxy} {_implementation} {_data}
```

where the parameters are:

- **_proxy** = {Optimism Portal Proxy Address}
- **_implementation** = {Address of the new implementation address, which is the StorageSetter. todo: I'm assuming these are deployed on Ethereum and Sepolia, verify and get those addresses}
- **_data** =  todo: figure out how to generate this

#### Tx #2. Reset l2Sender in OptimismPortalProxy

- **Name:** Reset l2Sender in OptimismPortalProxy
- **Description:** Pre-initialization of the OptimismPortal2
- **To:** {Optimism Portal Proxy Address}
- **Value:** 0
- **Function Signature:** setAddress(bytes32,address)
- **Raw Input Data:** 

To generate the raw input data, use the following command:

```bash
cast calldata "setAddress(bytes32,address)" 0x0000000000000000000000000000000000000000000000000000000000000032 0x0000000000000000000000000000000000000000
```

where the parameters are:

- **_slot**: https://github.com/ethereum-optimism/optimism/blob/d8807a56648263121abea50985418a236b9eddae/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L31-L36
- **_address**: zero address

#### Tx #3. Upgrade the OptimismPortal

- **Name:** Upgrade the OptimismPortal
- **Description:** Upgrade and initialize the OptimismPortal to OptimismPortal2 (3.10.0)
- **To:** {L1 Proxy Admin Address}
- **Value:** 0
- **Function Signature:** upgradeAndCall(address,address,bytes)
- **Raw Input Data:** 

To generate the raw input data, use the following command:

```bash
cast calldata "upgradeAndCall(address,address,bytes)"  {_proxy} {_implementation} {_data}
```

where the parameters are: 

- **_proxy** = {Optimism Portal Proxy Address}
- **_implementation** = {Address of the new implementation address of the OptimismPortal2 implementation}
- **_data** =  todo: figure out how to generate this

#### Tx #4. Upgrade SystemConfig to StorageSetter

- **Name:** `Upgrade SystemConfig to StorageSetter`
- **Description:** Upgrades the `SystemConfig` proxy to the `StorageSetter` contract in preparation for clearing the legacy `L2OutputOracle` storage slot and set the new `DisputeGameFactory` storage slot to contain the address of the `DisputeGameFactory` proxy.
- **To:** {L1 Proxy Admin Address}
- **Value:** 0
- **Function Signature:** upgrade(address,address)
- **Raw Input Data:** 

To generate the raw input data, use the following command:

```bash
cast calldata "upgrade(address,address)" {_proxy} {_implementation}
```

where the parameters are:

- **_proxy** = {System Config Proxy Address}
- **_implementation** = {Address of the new implementation address, which is the StorageSetter. todo: I'm assuming these are deployed on Ethereum and Sepolia, verify and get those addresses}

#### Tx #5. Clear SystemConfig's L2OutputOracle slot

- **Name:** Clear SystemConfig's L2OutputOracle slot
- **Description:** clears the keccak(systemconfig.l2outputoracle)-1 slot
- **To:** {System Config Proxy Address}
- **Value:** 0
- **Function Signature:** setAddress(bytes32,address)
- **Raw Input Data:** 

To generate the raw input data, use the following command:

```bash
cast calldata "setAddress(bytes32,address)" {_slot} 0x0000000000000000000000000000000000000000
```

where the parameters are:

- **_slot:** todo: where's the slot for this? This is the one in the OP Mainnet fp upgrade, but it seems odd: `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`
- **_address:** zero address


#### Tx #6. Set SystemConfig's DisputeGameFactory slot

- **Name:** Set SystemConfig's DisputeGameFactory slot
- **Description:** sets the keccak(systemconfig.disputegamefactory)-1 slot
- **To:** {System Config Proxy Address}
- **Value:** 0
- **Function Signature:** setAddress(bytes32,address)
- **Raw Input Data:** 

To generate the raw input data, use the following command:

```bash
cast calldata "setAddress(bytes32,address)" {_slot} {_address}
```

where the parameters are:

- **_slot:** odo: where's the slot for this? This is the one in the OP Mainnet fp upgrade, but it seems odd: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
- **_address:** {Dispute Game Factory Proxy Address}


#### Tx #7. Upgrade SystemConfig to 2.2.0

- **Name:** Upgrade SystemConfig to 2.2.0
- **Description:** Upgrade SystemConfig to 2.2.0
- **To:** {L1 Proxy Admin Address}
- **Value:** 0
- **Function Signature:** upgrade(address,address)
- **Raw Input Data:** 

To generate the raw input data, use the following command:

```bash
cast calldata "upgrade(address,address)" {_proxy} {_implementation}
```

where the parameters are:

**_proxy:** {System Config Proxy Address}
**_implementation:** {System Config Implementation Address}


#### Generate with msup

Use the `msup` tool to generate the safe transaction bundle:

```bash
./target/debug/msup generate --output input.json
```

### Simulate and Validate (todo)

Now your task folder is prepared. Navigate into that directory and execute the following command:

```
SIMULATE_WITHOUT_LEDGER=1 just \                    
  --dotenv-path .env \
  --justfile ../../../single.just \
  simulate
```

If all goes well, your output should look similar to this:

```bash

```

- Copy the entire `https://dashboard.tenderly.co/....` URL and paste it into your browser.
  - Make sure to include the `contractAddress`, `storage`, `key`, `value`, `contractAddress`, and `storage` parameters.
    - Note: Due to the data in this URL, you cannot just click the link from some terminals (like VSCode’s) directly. Instead you will have to highlight the whole link and copy/paste it.
- The tenderly UI will ask you to select a project—select any one.
- Scroll down and click the “Simulate Transaction” button.
- In the part that looks like the image below, sanity check these values. For example, make sure the block number is close to the latest block for the chain, ensure the sender is correct, and that the gas used seems sensible.
- Please make sure that the `Data to sign` matches what you see in the simulation and on your hardware wallet. This is a critical step that must not be skipped. Copy the `Data to sign:` from your terminal output and search the Tenderly Simulated Transaction and ensure its there.
- Then click the “State” tab at the top to see the state diff. 

#### Update Validation.md (todo)

Update the validation file to match the tenderly simulation user interface.

- Use the superchain registry to find the chain’s addresses. Look for the file will be located at `superchain/configs/mainnet/{network}/{chainName}.toml`.
- Replace all of the placeholder values.
- Ensure the order of the state changes match Tenderly.
- Ensure the etherscan links are correct.

### Add New Chain to CircleCI (todo)

Before the task is executed, it should be added to the CircleCI config to ensure it continues to pass even as changes are made to the repo prior to execution.

Add the following to the `jobs` in the `.circleci/config.yml` file:

```yml
just_simulate_[eth or sep]-[chain-name]-[index]-key-handover:
    docker:
      - image: <<pipeline.parameters.ci_builder_image>>
    steps:
      - checkout
      - run:
          name: just simulate [eth or sep]/[chain-name]-[index]-key-handover
          command: |
            go install github.com/mikefarah/yq/v4@latest
            just install
            cd tasks/[eth or sep]/[chain-name]-[index]-key-handover
            export SIMULATE_WITHOUT_LEDGER=1
            just \
            --dotenv-path $(pwd)/.env \
            --justfile ../../../single.just \
            simulate
```

The add the following to the workflows.main.jobs section at the bottom:

```
- just_simulate_[eth or sep]-[chain-name]-[index]-key-handover
```

### Open PR

Once the task folder has been prepared, you can open a PR with the following 
information:

```md
pr title: tasks([eth or sep]/[chain-short-name]) <chain-name> key handover

**Description**

<chain-name> Key Handover task has been prepared.
```

### Sign

Follow steps 4 and 5 in `SINGLE.md`

### Facilitators Execute

Ensure you properly fill out your `.env` file and follow the last section of the `SINGLE.md` file.

### Post Execution

#### superchain-ops (todo)

Once the task is executed, the job can be removed from CI and the task status 
should be updated to: `[EXECUTED](block-explorer-transaction-execution-link)`.
Then opening a PR to the repo with the following information:

```md
pr title: <chain-name> Key Handover Executed

**Description**

The <chain-name> key handover task has been executed.
```

#### superchain-registry (todo)

The Superchain Registry needs to be updated. You can do that by modifying the 
`ProxyAdminOwner` in the `superchain/configs/<superchain-target>/<chain-short-name>.toml` 
and then running `just codegen` from the root of the repository. Then opening
a PR to the repo with the following information:

```md
pr title: <chain-name> key handover executed

**Description**

- The <chain-name> Key Handover [task](<merged-task>)
- I've updated the ProxyAdminOwners for the network to the new owner, the same one as OP <Mainnet or Sepolia>. I did this by modifying the `superchain/configs/sepolia/<chain-short-name>.toml` and then running `just codegen`.
```
