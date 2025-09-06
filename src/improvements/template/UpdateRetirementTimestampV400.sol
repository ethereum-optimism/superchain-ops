// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface IAnchorStateRegistry {
    function updateRetirementTimestamp() external;
    function retirementTimestamp() external view returns (uint64);
}

/// @notice A template to update the retirement timestamp on the AnchorStateRegistry,
/// which will retire (invalidate) all existing dispute games.
/// Supports: op-contracts/v4.0.0
contract UpdateRetirementTimestampV400 is L2TaskBase {
    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "Guardian";
    }

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "AnchorStateRegistryProxy";
        return storageWrites;
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            // Get config for this chain
            uint256 chainId = chains[i].chainId;
            asr(chainId).updateRetirementTimestamp();
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        // Iterate over the chains and validate the retirement timestamp.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            assertEq(asr(chainId).retirementTimestamp(), block.timestamp);
        }
    }

    function asr(uint256 _chainId) internal view returns (IAnchorStateRegistry) {
        address asrAddr = superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", _chainId);
        return IAnchorStateRegistry(asrAddr);
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal pure override returns (address[] memory) {}
}
