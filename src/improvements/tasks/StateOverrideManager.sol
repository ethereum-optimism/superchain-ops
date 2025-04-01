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
    /// with user-defined overrides. User defined overrides either replace or append to the
    /// default overrides.
    /// If a child multisig is provided then we are working with a nested safe.
    /// In this case we need additional state overrides.
    function getStateOverrides(address parentMultisig, address optionalChildMultisig)
        public
        view
        returns (Simulation.StateOverride[] memory allOverrides_)
    {
        uint256 baseLength = (optionalChildMultisig != address(0)) ? 2 : 1;
        allOverrides_ = new Simulation.StateOverride[](baseLength + _stateOverrides.length);

        if (optionalChildMultisig != address(0)) {
            allOverrides_[0] = _parentMultisigTenderlyOverride(parentMultisig);
            allOverrides_[1] = _childMultisigTenderlyOverride(optionalChildMultisig);
        } else {
            allOverrides_[0] = _parentMultisigTenderlyOverride(parentMultisig, msg.sender);
        }

        // Merge user-defined overrides or append them if not merged
        for (uint256 i = 0; i < _stateOverrides.length; i++) {
            (Simulation.StateOverride[] memory updates, bool merged) =
                _mergeExistingOverrides(allOverrides_, _stateOverrides[i]);
            allOverrides_ = updates;

            if (!merged) {
                allOverrides_[baseLength + i] = _stateOverrides[i];
            }
        }

        allOverrides_ = _sanitizeOverrides(allOverrides_);
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
    function _parentMultisigTenderlyOverride(address parentMultisig, address owner)
        private
        view
        returns (Simulation.StateOverride memory defaultOverride)
    {
        defaultOverride.contractAddress = parentMultisig;
        defaultOverride = Simulation.addThresholdOverride(defaultOverride.contractAddress, defaultOverride);
        // We need to override the owner on the parent multisig to ensure single safes can execute.
        defaultOverride = Simulation.addOwnerOverride(parentMultisig, defaultOverride, owner);
    }

    /// @notice Parent multisig override for nested execution.
    function _parentMultisigTenderlyOverride(address parentMultisig)
        private
        view
        returns (Simulation.StateOverride memory defaultOverride)
    {
        defaultOverride.contractAddress = parentMultisig;
        defaultOverride = Simulation.addThresholdOverride(defaultOverride.contractAddress, defaultOverride);
    }

    /// @notice Create default state override for the child multisig.
    function _childMultisigTenderlyOverride(address childMultisig)
        private
        view
        returns (Simulation.StateOverride memory defaultOverride)
    {
        defaultOverride.contractAddress = childMultisig;
        defaultOverride = Simulation.addThresholdOverride(defaultOverride.contractAddress, defaultOverride);
        defaultOverride = Simulation.addOwnerOverride(childMultisig, defaultOverride, MULTICALL3_ADDRESS);
    }

    /// @notice Read state overrides from a TOML config file.
    /// Parses the TOML file and extracts state overrides for specific contracts.
    function _readStateOverridesFromConfig(string memory taskConfigFilePath)
        internal
        returns (Simulation.StateOverride[] memory)
    {
        string memory toml = vm.readFile(taskConfigFilePath);
        string memory stateOverridesKey = ".stateOverrides";

        // Skip if no state overrides section is found
        if (!toml.keyExists(stateOverridesKey)) return _stateOverrides;

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
        return _stateOverrides;
    }

    /// @notice When a user defines an override that already exists in the default overrides,
    /// we get an empty override that needs to be removed.
    function _sanitizeOverrides(Simulation.StateOverride[] memory overrides_)
        internal
        pure
        returns (Simulation.StateOverride[] memory sanitized_)
    {
        if (overrides_.length == 0) return overrides_;

        uint256 emptyOverridesToRemove = 0;
        for (uint256 i = 0; i < overrides_.length; i++) {
            if (overrides_[i].contractAddress == address(0)) {
                emptyOverridesToRemove++;
            }
        }

        sanitized_ = new Simulation.StateOverride[](overrides_.length - emptyOverridesToRemove);
        uint256 sanitizedIndex = 0;
        for (uint256 i = 0; i < overrides_.length; i++) {
            if (overrides_[i].contractAddress != address(0)) {
                sanitized_[sanitizedIndex] = overrides_[i];
                sanitizedIndex++;
            }
        }
        return sanitized_;
    }

    /// @notice Merge existing overrides with user-defined overrides.
    /// User-defined overrides take precedence over default ones. If a user-defined
    /// override’s key is missing in the default overrides for the matching contract,
    /// it is appended.
    function _mergeExistingOverrides(
        Simulation.StateOverride[] memory defaultOverrides_,
        Simulation.StateOverride memory userDefinedOverride_
    ) internal pure returns (Simulation.StateOverride[] memory updatedOverrides, bool merged_) {
        merged_ = false;
        for (uint256 j = 0; j < defaultOverrides_.length; j++) {
            if (defaultOverrides_[j].contractAddress == userDefinedOverride_.contractAddress) {
                merged_ = true;
                // Update existing keys or append new ones
                for (uint256 l = 0; l < userDefinedOverride_.overrides.length; l++) {
                    bool found = false;

                    for (uint256 k = 0; k < defaultOverrides_[j].overrides.length; k++) {
                        if (defaultOverrides_[j].overrides[k].key == userDefinedOverride_.overrides[l].key) {
                            defaultOverrides_[j].overrides[k].value = userDefinedOverride_.overrides[l].value;
                            found = true;
                            break;
                        }
                    }
                    // Append new key if not found
                    if (!found) {
                        uint256 oldLength = defaultOverrides_[j].overrides.length;
                        uint256 newLength = oldLength + 1;

                        Simulation.StorageOverride[] memory newOverrides = new Simulation.StorageOverride[](newLength);
                        for (uint256 m = 0; m < oldLength; m++) {
                            newOverrides[m] = defaultOverrides_[j].overrides[m];
                        }
                        newOverrides[oldLength] = userDefinedOverride_.overrides[l];

                        defaultOverrides_[j].overrides = newOverrides;
                    }
                }
                break; // Exit after processing the matching contract
            }
        }
        return (defaultOverrides_, merged_);
    }
}
