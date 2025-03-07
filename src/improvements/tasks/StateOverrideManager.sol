// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

contract StateOverrideManager {
    using stdToml for string;

    address private constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm private constant vm = Vm(VM_ADDRESS);

    /// @notice The state overrides for the local and tenderly simulation
    Simulation.StateOverride[] internal _stateOverrides;

    function getStateOverrides(address parentMultisig, uint256 parentMultisigNonce)
        public
        view
        returns (Simulation.StateOverride[] memory)
    {
        // Append user defined overrides to the default tenderly overrides.
        // This means that the user defined overrides take precedence over the default tenderly overrides.
        Simulation.StateOverride memory defaultOverride =
            _createDefaultTenderlyOverride(parentMultisig, parentMultisigNonce);
        Simulation.StateOverride[] memory overrides = new Simulation.StateOverride[](1 + _stateOverrides.length);
        overrides[0] = defaultOverride;
        for (uint256 i = 0; i < _stateOverrides.length; i++) {
            overrides[i + 1] = _stateOverrides[i];
        }
        return overrides;
    }

    /// @notice This function must be called first before any other function that uses state overrides.
    function _applyStateOverrides(string memory taskConfigFilePath) internal {
        _readStateOverrides(taskConfigFilePath);
        for (uint256 i = 0; i < _stateOverrides.length; i++) {
            for (uint256 j = 0; j < _stateOverrides[i].overrides.length; j++) {
                vm.store(
                    address(_stateOverrides[i].contractAddress),
                    _stateOverrides[i].overrides[j].key,
                    _stateOverrides[i].overrides[j].value
                );
            }
        }
    }

    /// @notice Creates a default state override for the parent multisig (nonce, threshold, owner).
    function _createDefaultTenderlyOverride(address parentMultisig, uint256 nonce)
        internal
        view
        returns (Simulation.StateOverride memory)
    {
        Simulation.StateOverride memory defaultOverride;
        defaultOverride.contractAddress = parentMultisig;
        defaultOverride = Simulation.addOverride(
            defaultOverride, Simulation.StorageOverride({key: bytes32(uint256(0x4)), value: bytes32(uint256(0x1))})
        );
        defaultOverride = Simulation.addOverride(
            defaultOverride, Simulation.StorageOverride({key: bytes32(uint256(0x5)), value: bytes32(nonce)})
        );
        defaultOverride = Simulation.addOwnerOverride(parentMultisig, defaultOverride, msg.sender);
        return defaultOverride;
    }

    function _readStateOverrides(string memory taskConfigFilePath) private {
        string memory toml = vm.readFile(taskConfigFilePath);
        string memory stateOverridesKey = ".stateOverrides";
        if (!toml.keyExists(stateOverridesKey)) return;

        string[] memory targetsStrs = vm.parseTomlKeys(toml, stateOverridesKey);
        Simulation.StateOverride[] memory stateOverridesMemory = new Simulation.StateOverride[](targetsStrs.length);

        address[] memory targetsAddrs = new address[](targetsStrs.length);
        for (uint256 i = 0; i < targetsStrs.length; i++) {
            targetsAddrs[i] = vm.parseAddress(targetsStrs[i]);
        }
        for (uint256 i = 0; i < targetsAddrs.length; i++) {
            Simulation.StorageOverride[] memory overrides = abi.decode(
                vm.parseToml(toml, string.concat(stateOverridesKey, ".", targetsStrs[i])),
                (Simulation.StorageOverride[])
            );
            stateOverridesMemory[i] = Simulation.StateOverride({contractAddress: targetsAddrs[i], overrides: overrides});
        }
        // Cannot assign the abi.decode result to `_stateOverrides` directly because it's a storage array, so
        // compiling without via-ir will fail with:
        // Unimplemented feature (/solidity/libsolidity/codegen/ArrayUtils.cpp:228):Copying of type struct Simulation.StateOverride memory[] memory to storage not yet supported.
        for (uint256 i = 0; i < stateOverridesMemory.length; i++) {
            // Push a new element into the storage array and get a reference to it.
            Simulation.StateOverride storage stateOverrideStorage = _stateOverrides.push();
            stateOverrideStorage.contractAddress = stateOverridesMemory[i].contractAddress;
            for (uint256 j = 0; j < stateOverridesMemory[i].overrides.length; j++) {
                stateOverrideStorage.overrides.push(stateOverridesMemory[i].overrides[j]);
            }
        }
    }

    function _getNonceOrOverride(address parentMultisig) internal view returns (uint256 nonce_) {
        bool foundNonceOverride = false;
        for (uint256 i = 0; i < _stateOverrides.length; i++) {
            bytes32 GNOSIS_SAFE_NONCE_SLOT = bytes32(uint256(0x5));
            for (uint256 j = 0; j < _stateOverrides[i].overrides.length; j++) {
                if (
                    _stateOverrides[i].contractAddress == parentMultisig
                        && _stateOverrides[i].overrides[j].key == GNOSIS_SAFE_NONCE_SLOT
                ) {
                    foundNonceOverride = true;
                    nonce_ = uint256(_stateOverrides[i].overrides[j].value);
                }
            }
        }
        if (!foundNonceOverride) {
            nonce_ = IGnosisSafe(parentMultisig).nonce();
        }
    }
}
