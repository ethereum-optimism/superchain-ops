// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface ISystemConfig {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}

/// @notice Template for transferring ownership of a chain's SystemConfig proxy.
/// The root Safe (current SystemConfig owner) MUST be configured via the top-level
/// `safeAddressString` key in the task's config.toml.
/// ATTENTION: Transferring ownership is high-risk — restricted to one chain per task.
contract TransferSystemConfigOwnership is L2TaskBase {
    using stdToml for string;

    /// @notice The new owner of the SystemConfig proxy.
    address public newOwner;

    /// @notice The single chain targeted by this task.
    SuperchainAddressRegistry.ChainInfo internal activeChain;

    /// @notice Must be set via the top-level `safeAddressString` key in the config file.
    function safeAddressString() public pure override returns (string memory) {
        revert("TransferSystemConfigOwnership: safeAddressString must be set in the config file");
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "SystemConfigProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with the new owner from a TOML file.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);

        string memory toml = vm.readFile(_taskConfigFilePath);
        newOwner = toml.readAddress(".newOwner");
        require(newOwner != address(0), "TransferSystemConfigOwnership: newOwner is zero address");

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        require(chains.length == 1, "TransferSystemConfigOwnership: exactly one chain required");
        activeChain = chains[0];

        address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", activeChain.chainId);
        address currentOwner = ISystemConfig(systemConfigProxy).owner();
        require(currentOwner != newOwner, "TransferSystemConfigOwnership: newOwner equals current owner");
        require(currentOwner == _rootSafe, "TransferSystemConfigOwnership: rootSafe is not current SystemConfig owner");
    }

    /// @notice Builds the action that transfers SystemConfig ownership.
    function _build(address) internal override {
        address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", activeChain.chainId);
        ISystemConfig(systemConfigProxy).transferOwnership(newOwner);
    }

    /// @notice Validates that ownership was transferred to the new owner.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        address systemConfigProxy = superchainAddrRegistry.getAddress("SystemConfigProxy", activeChain.chainId);
        require(
            ISystemConfig(systemConfigProxy).owner() == newOwner, "TransferSystemConfigOwnership: owner not updated"
        );
    }

    /// @notice newOwner may be an EOA, an undeployed Safe (no code at the fork block), or
    /// a deployed Safe (has code). The state-diff check classifies storage values into
    /// "should have code" / "should not have code"; the codeExceptions list is the set
    /// of addresses we declare *will not* have code. Add newOwner only if it actually
    /// has no code at simulation time — otherwise let the standard "should have code"
    /// check pass naturally.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        if (newOwner.code.length == 0) {
            address[] memory exceptions = new address[](1);
            exceptions[0] = newOwner;
            return exceptions;
        }
        return new address[](0);
    }
}
