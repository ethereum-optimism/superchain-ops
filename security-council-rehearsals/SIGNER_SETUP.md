# Signer Setup Instructions

This guide provides setup instructions for Security Council members participating in rehearsals.

## Repository Setup

Run these commands **once** when you first clone the repository or when instructed by the facilitator:

```bash
cd superchain-ops
git pull
mise trust mise.toml # Only required the first time you use the repository.
mise install
mise activate # Activate mise for the current shell; if it doesn't take effect, restart your terminal.
forge clean
forge install
```

For more details on repository setup and dependencies, see the main [README](../README.md).

## Hardware Wallet Setup

### Default Setup (Ledger)

Your hardware wallet needs to be connected and unlocked. The Ethereum application needs to be opened on your hardware wallet with the message "Application is ready".

By default, the tooling uses the first Ethereum account on your hardware wallet (derivation path `m/44'/60'/0'/0/0`).

### Using a Different Derivation Path

If you need to use a different Ethereum account on your hardware wallet, you can specify the HD_PATH environment variable:

```bash
# Use the second account (m/44'/60'/1'/0/0)
HD_PATH=1 just simulate-stack <network> rehearsals/<rehearsal-task-name>
HD_PATH=1 just sign-stack <network> rehearsals/<rehearsal-task-name>
```

The `HD_PATH` value is used as an index in the BIP44 Ethereum path: `m/44'/60'/$HD_PATH'/0/0`.

### Using a Different Hardware Wallet

The tooling supports any hardware wallet that works with Foundry's signing tools. Common options include:
- Ledger devices (Nano S, Nano X, Nano S Plus)
- Trezor devices
- Any wallet compatible with Foundry's `cast wallet` command

### Using Keystore Instead of Hardware Wallet

If you prefer to use a keystore file instead of a hardware wallet:

1. First, import your private key into Foundry's keystore:
   ```bash
   cast wallet import my-account-name --private-key <your-private-key>
   ```

2. Then use the `USE_KEYSTORE` environment variable when running commands:
   ```bash
   USE_KEYSTORE=1 just simulate-stack <network> rehearsals/<rehearsal-task-name>
   USE_KEYSTORE=1 just sign-stack <network> rehearsals/<rehearsal-task-name>
   ```

You'll be prompted for your keystore password when signing.

For more information on hardware wallet configuration, see the [main README](../README.md#how-do-i-sign-a-task-that-depends-on-another-task).
