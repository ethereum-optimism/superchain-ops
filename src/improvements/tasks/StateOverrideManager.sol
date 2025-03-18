// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Script} from "forge-std/Script.sol";

/// @notice Manages state overrides for transaction simulation.
/// This contract is used by MultisigTask to simulate transactions
/// with specific state conditions.
abstract contract StateOverrideManager is Script {
    using stdToml for string;

    /// @notice Gnosis Safe storage slots for important state variables
    uint256 private constant GNOSIS_SAFE_THRESHOLD_SLOT = 0x4;
    uint256 private constant GNOSIS_SAFE_NONCE_SLOT = 0x5;

    /// @notice The state overrides for the local and tenderly simulation
    Simulation.StateOverride[] private _stateOverrides;

    /// @notice Get all state overrides for simulation. Combines default Tenderly overrides
    /// with user-defined overrides. User defined overrides are applied last.
    function getStateOverrides(
        address parentMultisig,
        uint256 parentMultisigNonce,
        address optionalChildMultisig,
        uint256 optionalChildMultisigNonce
    ) public view returns (Simulation.StateOverride[] memory) {
        Simulation.StateOverride[] memory allOverrides;
        if (optionalChildMultisig != address(0)) {
            allOverrides = new Simulation.StateOverride[](2 + _stateOverrides.length);
            allOverrides[0] = _createDefaultParentMultisigTenderlyOverride(parentMultisig, parentMultisigNonce);
            allOverrides[1] =
                _createDefaultChildMultisigTenderlyOverride(optionalChildMultisig, optionalChildMultisigNonce);
        } else {
            allOverrides = new Simulation.StateOverride[](1 + _stateOverrides.length);
            allOverrides[0] = _createDefaultParentMultisigTenderlyOverride(parentMultisig, parentMultisigNonce);
        }

        // Add user-defined overrides (these take precedence over default ones)
        for (uint256 i = 0; i < _stateOverrides.length; i++) {
            allOverrides[i + 1] = _stateOverrides[i];
        }

        return allOverrides;
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

    /// @notice Create default state override for the parent multisig.
    function _createDefaultParentMultisigTenderlyOverride(address parentMultisig, uint256 nonce)
        private
        pure
        returns (Simulation.StateOverride memory)
    {
        Simulation.StateOverride memory defaultOverride;
        defaultOverride.contractAddress = parentMultisig;
        defaultOverride = _overrideMultisigThresholdAndNonce(defaultOverride, 1, nonce);
        return defaultOverride;
    }

    /// @notice Create default state override for the child multisig.
    function _createDefaultChildMultisigTenderlyOverride(address childMultisig, uint256 nonce)
        private
        view
        returns (Simulation.StateOverride memory)
    {
        Simulation.StateOverride memory defaultOverride;
        defaultOverride.contractAddress = childMultisig;
        defaultOverride = _overrideMultisigThresholdAndNonce(defaultOverride, 1, nonce);
        // Set owner to the MULTICALL3_ADDRESS - We do this because we want to perform two actions during the Tenderly simulation.
        // 1. Call approveHash from the child multisig.
        // 2. Call execTransaction on the parent multisig (with a prevalidated signature from the previous step).
        defaultOverride = Simulation.addOwnerOverride(childMultisig, defaultOverride, MULTICALL3_ADDRESS);
        return defaultOverride;
    }

    /// @notice Helper function to override the threshold and nonce for a multisig.
    function _overrideMultisigThresholdAndNonce(
        Simulation.StateOverride memory defaultOverride,
        uint256 threshold,
        uint256 nonce
    ) private pure returns (Simulation.StateOverride memory) {
        defaultOverride = Simulation.addOverride(
            defaultOverride,
            Simulation.StorageOverride({key: bytes32(GNOSIS_SAFE_THRESHOLD_SLOT), value: bytes32(threshold)})
        );
        defaultOverride = Simulation.addOverride(
            defaultOverride, Simulation.StorageOverride({key: bytes32(GNOSIS_SAFE_NONCE_SLOT), value: bytes32(nonce)})
        );
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
