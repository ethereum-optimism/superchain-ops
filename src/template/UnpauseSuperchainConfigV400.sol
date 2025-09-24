// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";

import {Action} from "src/libraries/MultisigTypes.sol";

/// @title UnpauseSuperchainConfigV400 template designed to unpause the SuperchainConfig contract after the U16 upgrade.
contract UnpauseSuperchainConfigV400 is L2TaskBase {
    using stdToml for string;

    /// @notice Identifier of the eth_lockbox used in the SuperchainConfig
    /// @dev Address (20 bytes) that has an associated lockbox contract, loaded from TOML
    address public identifier;

    /// @notice SuperchainConfig SC contract instance
    ISuperchainConfig public sc;

    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "Guardian";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "SuperchainConfig";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory file = vm.readFile(_taskConfigFilePath);
        identifier = vm.parseTomlAddress(file, ".identifier"); // Get the identifier of the eth_lockbox from the TOML file
        // Load the SuperchainConfig contract.
        sc = ISuperchainConfig(superchainAddrRegistry.get("SuperchainConfig"));
        // Make sure that the SuperchainConfig is paused before unpausing for the identifier.
        assertEq(sc.paused(identifier), true, "ERR100: SuperchainConfig should be paused for the identifier provided.");
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build(address) internal override {
        /// Unpause the SuperchainConfig contract through the identifier.
        sc.unpause(identifier);
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        // Validate that the SuperchainConfig contract is unpaused.
        // check that the Superchain Config is not paused anymore with the identifier provided.
        assertEq(
            sc.paused(identifier), false, "ERR101: SuperchainConfig should be unpaused for the identifier provided."
        );
        if (
            identifier != address(0) // If the identifier is 0 this indicates a superchain-wide pause so we don't need to check the lockbox associated
        ) {
            assertEq(
                IETHLockbox(identifier).paused(),
                false,
                "ERR102: ETHLockbox should be unpaused for the identifier provided."
            );
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface IETHLockbox {
    function paused() external view returns (bool);
}

interface ISuperchainConfig {
    function guardian() external view returns (address);

    function pause(address _identifier) external;

    function unpause(address _identifier) external;

    function paused() external view returns (bool);

    function paused(address _identifier) external view returns (bool);
}
