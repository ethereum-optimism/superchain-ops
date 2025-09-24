// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {CommonBase} from "forge-std/Base.sol";
import {Utils} from "src/libraries/Utils.sol";

/// @notice Manages state overrides for transaction simulation.
/// This contract is used by MultisigTask to simulate transactions
/// with specific state conditions.
abstract contract StateOverrideManager is CommonBase {
    using stdToml for string;

    /// @notice The state overrides for the local and tenderly simulation
    Simulation.StateOverride[] private _stateOverrides;

    /// @notice Get all state overrides when simulating arbitrarily nested safes.
    /// Applies threshold=1 to root safe and all child safes, and adds MULTICALL3_ADDRESS as an owner to each child safe.
    function getStateOverrides(address rootSafe, address[] memory childSafes)
        public
        view
        returns (Simulation.StateOverride[] memory allOverrides_)
    {
        uint256 childCount = childSafes.length;
        Simulation.StateOverride[] memory defaultOverrides = new Simulation.StateOverride[](1 + childCount);

        // Root safe override: set threshold to 1. Add owner only for single-safe.
        defaultOverrides[0] = _rootSafeTenderlyOverride(rootSafe, childCount > 0 ? address(0) : msg.sender);

        // For each child: threshold=1 and add MULTICALL3_ADDRESS as owner
        for (uint256 i = 0; i < childCount; i++) {
            defaultOverrides[1 + i] = _childSafeTenderlyOverride(childSafes[i]);
        }

        allOverrides_ = defaultOverrides;
        for (uint256 j = 0; j < _stateOverrides.length; j++) {
            allOverrides_ = _appendUserDefinedOverrides(allOverrides_, _stateOverrides[j]);
        }
    }

    /// @notice Apply state overrides to the current VM state.
    /// Must be called before any function that expects the overridden state.
    function _applyStateOverrides() internal {
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
    /// An important part of this function is to perform nonce safety checks. It ensures that
    /// user-defined nonces are not less than the current actual nonce.
    function _getNonceOrOverride(address safeAddress, string memory _taskConfigFilePath)
        internal
        view
        returns (uint256 nonce_)
    {
        uint256 currentActualNonce = IGnosisSafe(safeAddress).nonce();

        uint256 GNOSIS_SAFE_NONCE_SLOT = 0x5;
        // Check if nonce is overridden in state overrides
        for (uint256 i = 0; i < _stateOverrides.length; i++) {
            // Skip if not the target contract
            if (_stateOverrides[i].contractAddress != safeAddress) continue;

            bytes32 nonceSlot = bytes32(GNOSIS_SAFE_NONCE_SLOT);

            for (uint256 j = 0; j < _stateOverrides[i].overrides.length; j++) {
                if (_stateOverrides[i].overrides[j].key == nonceSlot) {
                    uint256 userDefinedNonce = uint256(_stateOverrides[i].overrides[j].value);
                    // This feature is used to disable the nonce check, via env var (DISABLE_OVERRIDE_NONCE_CHECK=1).
                    if (!Utils.isFeatureEnabled("DISABLE_OVERRIDE_NONCE_CHECK")) {
                        // This is an important safety check. Users should not be able to set the nonce to a value less than the current actual nonce.
                        require(
                            userDefinedNonce >= currentActualNonce,
                            string.concat(
                                "StateOverrideManager: User-defined nonce (",
                                vm.toString(userDefinedNonce),
                                ") is less than current actual nonce (",
                                vm.toString(currentActualNonce),
                                ") for contract: ",
                                vm.toString(safeAddress),
                                " in task config file: ",
                                _taskConfigFilePath
                            )
                        );
                    }
                    return userDefinedNonce;
                }
            }
        }

        // No override found, use the current actual nonce.
        return currentActualNonce;
    }

    /// @notice Root safe override. If `owner` is non-zero, it will be added as an owner when not already.
    function _rootSafeTenderlyOverride(address rootSafe, address owner)
        private
        view
        returns (Simulation.StateOverride memory defaultOverride)
    {
        defaultOverride.contractAddress = rootSafe;
        defaultOverride = Simulation.addThresholdOverride(defaultOverride.contractAddress, defaultOverride);

        // We need to override the owner on the root safe to ensure single safes can execute but only if the owner is not already an owner.
        if (owner != address(0) && !IGnosisSafe(rootSafe).isOwner(owner)) {
            defaultOverride = Simulation.addOwnerOverride(rootSafe, defaultOverride, owner);
        }
    }

    /// @notice Create default state override for the child safe.
    function _childSafeTenderlyOverride(address childSafe)
        private
        view
        returns (Simulation.StateOverride memory defaultOverride)
    {
        defaultOverride.contractAddress = childSafe;
        defaultOverride = Simulation.addThresholdOverride(defaultOverride.contractAddress, defaultOverride);
        defaultOverride = Simulation.addOwnerOverride(childSafe, defaultOverride, MULTICALL3_ADDRESS);
    }

    /// @notice Read state overrides from a TOML config file.
    /// Parses the TOML file and extracts state overrides for specific contracts.
    function _setStateOverridesFromConfig(string memory taskConfigFilePath)
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
            bytes memory tomlOverrides = vm.parseToml(toml, overridesPath);
            Simulation.StorageOverride[] memory storageOverrides =
                abi.decode(tomlOverrides, (Simulation.StorageOverride[]));

            // Reencode the overrides back to bytes and ensure that the roundtrip encoding is the same as the original.
            // This is a hacky form of type safety to make up for the lack of it in the toml parser.
            bytes memory reencoded = abi.encode(storageOverrides);
            require(
                keccak256(reencoded) == keccak256(tomlOverrides),
                "StateOverrideManager: Failed to reencode overrides, ensure any decimal numbers are not in quotes"
            );

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

    /// @notice Append user-defined overrides to default overrides.
    /// This function will revert if a user-defined override is duplicated or if it attempts to overwrite an existing default override.
    function _appendUserDefinedOverrides(
        Simulation.StateOverride[] memory defaultOverrides_,
        Simulation.StateOverride memory userDefinedOverride_
    ) internal pure returns (Simulation.StateOverride[] memory) {
        // Check for duplicates in the user defined overrides first.
        _validateNoDuplicates(userDefinedOverride_.overrides, userDefinedOverride_.contractAddress);

        bool foundContract;

        // Check if the contract address exists in the default overrides (append if it does).
        for (uint256 j = 0; j < defaultOverrides_.length; j++) {
            if (defaultOverrides_[j].contractAddress == userDefinedOverride_.contractAddress) {
                // Validate ALL user overrides against ORIGINAL defaults first
                _validateAgainstDefaults(
                    defaultOverrides_[j].overrides, userDefinedOverride_.overrides, userDefinedOverride_.contractAddress
                );

                // Append after validation
                Simulation.StorageOverride[] memory combined = new Simulation.StorageOverride[](
                    defaultOverrides_[j].overrides.length + userDefinedOverride_.overrides.length
                );

                uint256 i = 0;
                for (; i < defaultOverrides_[j].overrides.length; i++) {
                    combined[i] = defaultOverrides_[j].overrides[i];
                }
                for (uint256 l = 0; l < userDefinedOverride_.overrides.length; l++) {
                    combined[i++] = userDefinedOverride_.overrides[l];
                }

                defaultOverrides_[j].overrides = combined;
                foundContract = true;
                break;
            }
        }

        // If the contract address does not exist in the default overrides, append the user defined override.
        if (!foundContract) {
            Simulation.StateOverride[] memory newOverrides =
                new Simulation.StateOverride[](defaultOverrides_.length + 1);
            for (uint256 j = 0; j < defaultOverrides_.length; j++) {
                newOverrides[j] = defaultOverrides_[j];
            }
            newOverrides[defaultOverrides_.length] = userDefinedOverride_;
            return newOverrides;
        }

        return defaultOverrides_;
    }

    function _validateNoDuplicates(Simulation.StorageOverride[] memory overrides, address contractAddress)
        internal
        pure
    {
        for (uint256 i = 0; i < overrides.length; i++) {
            for (uint256 j = i + 1; j < overrides.length; j++) {
                if (overrides[i].key == overrides[j].key) {
                    revert(
                        string.concat(
                            "StateOverrideManager: Duplicate keys in user-defined overrides for contract: ",
                            vm.toString(contractAddress)
                        )
                    );
                }
            }
        }
    }

    function _validateAgainstDefaults(
        Simulation.StorageOverride[] memory defaults,
        Simulation.StorageOverride[] memory userOverrides,
        address contractAddress
    ) internal pure {
        for (uint256 l = 0; l < userOverrides.length; l++) {
            for (uint256 k = 0; k < defaults.length; k++) {
                if (defaults[k].key == userOverrides[l].key) {
                    revert(
                        string.concat(
                            "StateOverrideManager: User-defined override is attempting to overwrite an existing default override for contract: ",
                            vm.toString(contractAddress)
                        )
                    );
                }
            }
        }
    }
}
