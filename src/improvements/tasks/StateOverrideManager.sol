// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {CommonBase} from "forge-std/Base.sol";

/// @notice Manages state overrides for transaction simulation.
/// This contract is used by MultisigTask to simulate transactions
/// with specific state conditions.
abstract contract StateOverrideManager is CommonBase {
    using stdToml for string;

    /// @notice The state overrides for the local and tenderly simulation
    Simulation.StateOverride[] private _stateOverrides;

    /// @notice Get all state overrides for simulation. Combines default Tenderly overrides
    /// with user-defined overrides. User defined overrides are applied last.
    /// If a child multisig is provided then we are working with a nested safe.
    /// In this case we need additional state overrides.
    function getStateOverrides(
        address parentMultisig,
        uint256 parentMultisigNonce,
        address optionalChildMultisig,
        uint256 optionalChildMultisigNonce
    ) public view returns (Simulation.StateOverride[] memory allOverrides_) {
        if (optionalChildMultisig != address(0)) {
            allOverrides_ = new Simulation.StateOverride[](2 + _stateOverrides.length);
            allOverrides_[0] = _parentMultisigTenderlyOverride(parentMultisig, parentMultisigNonce);
            allOverrides_[1] = _childMultisigTenderlyOverride(optionalChildMultisig, optionalChildMultisigNonce);
            // Add user-defined overrides (these take precedence over default ones)
            for (uint256 i = 0; i < _stateOverrides.length; i++) {
                allOverrides_[i + 2] = _stateOverrides[i];
            }
        } else {
            allOverrides_ = new Simulation.StateOverride[](1 + _stateOverrides.length);
            allOverrides_[0] = _parentMultisigTenderlyOverride(parentMultisig, parentMultisigNonce, msg.sender);
            for (uint256 i = 0; i < _stateOverrides.length; i++) {
                allOverrides_[i + 1] = _stateOverrides[i];
            }
        }
    }

    /// @notice Apply state overrides to the current VM state.
    /// Must be called before any function that expects the overridden state.
    function _applyStateOverrides(string memory taskConfigFilePath) internal {
        _readStateOverridesFromConfig(taskConfigFilePath);

        // Apply each override to the VM state
        for (uint256 i = 0; i < _stateOverrides.length; i++) {
            address targetContract = address(_stateOverrides[i].contractAddress);

            for (uint256 j = 0; j < _stateOverrides[i].overrides.length; j++) {
                bytes32 slot = _stateOverrides[i].overrides[j].key;
                bytes32 value = _stateOverrides[i].overrides[j].value;

                // Write the overridden value to storage
                vm.store(targetContract, slot, value);
            }
        }
    }

    /// @notice Get the nonce for a Safe, preferring overridden values if available.
    /// Checks if nonce is overridden in the state overrides, otherwise gets from contract.
    function _getNonceOrOverride(address safeAddress) internal view returns (uint256 nonce_) {
        uint256 GNOSIS_SAFE_NONCE_SLOT = 0x5;
        // Check if nonce is overridden in state overrides
        for (uint256 i = 0; i < _stateOverrides.length; i++) {
            // Skip if not the target contract
            if (_stateOverrides[i].contractAddress != safeAddress) continue;

            bytes32 nonceSlot = bytes32(GNOSIS_SAFE_NONCE_SLOT);

            for (uint256 j = 0; j < _stateOverrides[i].overrides.length; j++) {
                if (_stateOverrides[i].overrides[j].key == nonceSlot) {
                    // Return the overridden nonce value
                    return uint256(_stateOverrides[i].overrides[j].value);
                }
            }
        }

        // No override found, get nonce directly from the contract
        return IGnosisSafe(safeAddress).nonce();
    }

    /// @notice Parent multisig override for single execution.
    function _parentMultisigTenderlyOverride(address parentMultisig, uint256 nonce, address owner)
        private
        view
        returns (Simulation.StateOverride memory defaultOverride)
    {
        defaultOverride.contractAddress = parentMultisig;
        defaultOverride = _overrideMultisigThresholdAndNonce(defaultOverride, nonce);
        // We need to override the owner on the parent multisig to ensure single safes can execute.
        defaultOverride = Simulation.addOwnerOverride(parentMultisig, defaultOverride, owner);
    }

    /// @notice Parent multisig override for nested execution.
    function _parentMultisigTenderlyOverride(address parentMultisig, uint256 nonce)
        private
        view
        returns (Simulation.StateOverride memory defaultOverride)
    {
        defaultOverride.contractAddress = parentMultisig;
        defaultOverride = _overrideMultisigThresholdAndNonce(defaultOverride, nonce);
    }

    /// @notice Create default state override for the child multisig.
    function _childMultisigTenderlyOverride(address childMultisig, uint256 nonce)
        private
        view
        returns (Simulation.StateOverride memory defaultOverride)
    {
        defaultOverride.contractAddress = childMultisig;
        defaultOverride = _overrideMultisigThresholdAndNonce(defaultOverride, nonce);
        defaultOverride = Simulation.addOwnerOverride(childMultisig, defaultOverride, MULTICALL3_ADDRESS);
    }

    /// @notice Helper function to override the threshold and nonce for a multisig.
    function _overrideMultisigThresholdAndNonce(Simulation.StateOverride memory defaultOverride, uint256 nonce)
        private
        view
        returns (Simulation.StateOverride memory)
    {
        defaultOverride = Simulation.addThresholdOverride(defaultOverride.contractAddress, defaultOverride);
        defaultOverride = Simulation.addNonceOverride(defaultOverride.contractAddress, defaultOverride, nonce);
        return defaultOverride;
    }

    /// @notice Read state overrides from a TOML config file.
    /// Parses the TOML file and extracts state overrides for specific contracts.
    function _readStateOverridesFromConfig(string memory taskConfigFilePath) private {
        string memory toml = vm.readFile(taskConfigFilePath);
        string memory stateOverridesKey = ".stateOverrides";

        // Skip if no state overrides section is found
        if (!toml.keyExists(stateOverridesKey)) return;

        // Get all target contract addresses
        string[] memory targetStrings = vm.parseTomlKeys(toml, stateOverridesKey);
        address[] memory targetAddresses = new address[](targetStrings.length);

        for (uint256 i = 0; i < targetStrings.length; i++) {
            targetAddresses[i] = vm.parseAddress(targetStrings[i]);
        }

        Simulation.StateOverride[] memory parsedOverrides = new Simulation.StateOverride[](targetAddresses.length);
        for (uint256 i = 0; i < targetAddresses.length; i++) {
            string memory overridesPath = string.concat(stateOverridesKey, ".", targetStrings[i]);
            Simulation.StorageOverride[] memory storageOverrides =
                abi.decode(vm.parseToml(toml, overridesPath), (Simulation.StorageOverride[]));

            parsedOverrides[i] =
                Simulation.StateOverride({contractAddress: targetAddresses[i], overrides: storageOverrides});
        }

        // Copy from memory to storage (can't assign directly to storage array)
        for (uint256 i = 0; i < parsedOverrides.length; i++) {
            Simulation.StateOverride storage stateOverrideStorage = _stateOverrides.push();
            stateOverrideStorage.contractAddress = parsedOverrides[i].contractAddress;

            for (uint256 j = 0; j < parsedOverrides[i].overrides.length; j++) {
                stateOverrideStorage.overrides.push(parsedOverrides[i].overrides[j]);
            }
        }
    }
}
