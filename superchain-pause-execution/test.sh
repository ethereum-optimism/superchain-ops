#!/bin/bash

### Testing script that will allow you to test until the deputyPauseModule is deployed.
## send eth to the deputyGuardian for the fees. 
cast send 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Impersonate the deputyGuardian account to add the new Deputy Pause Module to the system.
cast rpc anvil_impersonateAccount 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E

# Enable the module that is currently new and not installed on the current deputyGuardian.

cast send 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E "enableModule(address)" 0xc6f7C07047ba37116A3FdC444Afb5018f6Df5758 --from 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E --unlocked


echo "isModuleEnabled:"$(cast call 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E "isModuleEnabled(address)(bool)" 0xc6f7C07047ba37116A3FdC444Afb5018f6Df5758)

