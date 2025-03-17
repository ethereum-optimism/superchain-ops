// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

/// @notice Manages state overrides for transaction simulation.
/// This contract is used by MultisigTask to simulate transactions
/// with specific state conditions.
abstract contract StateOverrideManager {
    using stdToml for string;

    address private constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm private constant vm = Vm(VM_ADDRESS);

    /// @notice Gnosis Safe storage slots for important state variables
    uint256 private constant GNOSIS_SAFE_THRESHOLD_SLOT = 0x4;
    uint256 private constant GNOSIS_SAFE_NONCE_SLOT = 0x5;

    /// @notice The state overrides for the local and tenderly simulation
    Simulation.StateOverride[] private _stateOverrides;

    /// @notice Get all state overrides for simulation. Combines default Tenderly overrides
    /// with user-defined overrides.
    function getStateOverrides(address parentMultisig, uint256 parentMultisigNonce)
        public
        view
        returns (Simulation.StateOverride[] memory)
    {
        // Create default Tenderly override (sets nonce, threshold, and makes msg.sender an owner)
        Simulation.StateOverride memory defaultOverride =
            _createDefaultTenderlyOverride(parentMultisig, parentMultisigNonce);

        // Combine default override with user-defined overrides
        Simulation.StateOverride[] memory allOverrides = new Simulation.StateOverride[](1 + _stateOverrides.length);
        allOverrides[0] = defaultOverride;

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
    function _createDefaultTenderlyOverride(address parentMultisig, uint256 nonce)
        private
        view
        returns (Simulation.StateOverride memory)
    {
        Simulation.StateOverride memory defaultOverride;
        defaultOverride.contractAddress = parentMultisig;

        // Set threshold to 1 (single signer)
        defaultOverride = Simulation.addOverride(
            defaultOverride,
            Simulation.StorageOverride({key: bytes32(GNOSIS_SAFE_THRESHOLD_SLOT), value: bytes32(uint256(0x1))})
        );

        // Set nonce to the provided value
        defaultOverride = Simulation.addOverride(
            defaultOverride, Simulation.StorageOverride({key: bytes32(GNOSIS_SAFE_NONCE_SLOT), value: bytes32(nonce)})
        );

        // Add msg.sender as an owner of the Safe
        defaultOverride = Simulation.addOwnerOverride(parentMultisig, defaultOverride, msg.sender);
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
