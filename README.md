# superchain-ops

This repo contains execution code and artifacts related to superchain deployments and other tasks.

This repo is structured with each network having a high level directory which contains sub directories of any "tasks" which have occured on that network.

Tasks include:

- new contract deployments
- contract upgrades
- onchain configuration changes

Effectively any significant change to the state of the network, requiring authorization to execute, should be considered a task.

## Directory structure

Top level directory names should be the [EIP-3770](https://eips.ethereum.org/EIPS/eip-3770) short name for the network (see [shortNameMapping.json](https://chainid.network/shortNameMapping.json))

Each task should contain the following:

- `README.md`: A brief markdown file describing the task to be executed.
- `Validation.md`: A markdown file describing and justifying the expected state changes for manual validation by multisig signers.
- `Script.s.sol`: A foundry script that implements post upgrade assertions.
- `input.json`: A JSON file which defines the specific transaction for the task to be executed. This file may either be generated automatically or manually created.
- `.env`: a place to store environment variables specific to this task

## Installation

The following instructions are for MacOS, but should be similar for other operating systems.

For each of these steps, if you already have some version of the software installed, it should be safe to skip it.

### Installing git

Very likely you have git on your system. To verify this, open a Terminal and type `git --version`.
If an error message shows, these are the steps to download and install it:

1. Go to the official Git website at https://git-scm.com/downloads
1. Download the appropriate installer for your operating system.
1. Run the installer and follow the instructions.
1. Once the installation is complete, open a command prompt or Git Bash and type `git --version`. You should see the version number of Git that you just installed.

### Installing Go

1. Go to the official Go website at https://golang.org/dl/
1. Download the appropriate installer for your operating system.
1. Run the installer and follow the instructions.

From the command prompt:
Type `go version`.

You should see the version number of Go that you just installed.

### Installing the Rust Toolchain

1. Visit the rust toolchain installer website at https://rustup.rs
1. Follow the instructions for your operating system to install `rustup`, and use `rustup` to install the Rust toolchain.
1. Verify the installation from the command prompt:
  - Type rustc --version
  - Type cargo --version.
 Both commands should print a version number.

### Installing eip712sign

We’ll use the [eip712sign](https://github.com/base-org/eip712sign) utility developed by Base for signing hashes:

1. From the command prompt run:
	`go install github.com/base-org/eip712sign@v0.0.3`
1. Verify the installation:
  Type  `$(go env GOPATH)/bin/eip712sign`.
You should see a message something like this:
  ` One (and only one) of --private-key, --ledger, --mnemonic must be set`

### Installing `mikefarah/yq`

We’ll use `mikefarah/yq` to parse `.yaml` files:

1. From the command prompt run:
  `go install github.com/mikefarah/yq/v4@latest`
2. Verify the installation by typing `$(go env GOPATH)/bin/yq --version`
3. You should see the version number printed. This repo has been tested with version `4.43.1`.

### Installing foundry

We’ll use foundry to simulate the transaction we’re approving:

1. From the command prompt run:
  `curl -L https://foundry.paradigm.xyz | bash`
1. Run foundryup
1. Verify the installation by typing `cast --version`
1. You should see the version number printed.

### Installing just

Just is a command runner, which is similar to `make`.

1. From the command prompt run:
  `cargo install just`
1. Verify the installation by typing `just --version`
1. You should see the version number printed. This repo has been tested with version `1.24.0`.

### Cloning the superchain-ops repo

The superchain-ops repo holds the tools and artifacts that define any on-chain actions taken to either upgrade our system, or modify its configuration.

1. Clone the superchain-ops repo
  `git clone https://github.com/ethereum-optimism/superchain-ops.git`
1. Or if you’ve already cloned, just pull the main branch:
  `git checkout main`
 	`git pull`

Move into the repo and install the contract dependencies

`just install-contracts`

### Create a Tenderly account

Tenderly is used to simulate transactions.
If you don’t already have a Tenderly account, go to https://dashboard.tenderly.co/login and sign up.
The free account is sufficient.

## Creating a Task

Each task in the `tasks` directory should contain all of the information required to both validate
and perform the network interaction. To validate that the intention of the network interaction is
correct, specific contextual information must be included in `Validation.md` that enables signers
to double check the correctness. This includes linking to authoritative sources such as the
[superchain-registry](https://github.com/ethereum-optimism/superchain-registry) or
[Etherscan](https://etherscan.io) to prove the correctness of particular configuration values.

The base scripts for performing network interactions found in the `script` directory should
be inherited from with the `Script.s.sol` file where the `_postCheck` hook is implemented.
This function should make assertions on the post state of the network interaction.
It will run each time that a signer generates a signature, giving additional automation
on validating the correctness of the network interaction.
