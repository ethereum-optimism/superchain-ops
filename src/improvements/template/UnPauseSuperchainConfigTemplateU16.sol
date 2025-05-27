// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

import {ISuperchainConfig} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/ISuperchainConfig.sol";

import {IOptimismPortal2} from "lib/optimism/packages/contracts-bedrock/interfaces/safe/IDeputyGuardianModule.sol";

interface IDeputyGuardianModuleU16 {
    error ExecutionFailed(string);
    error Unauthorized();

    function version() external view returns (string memory);

    function pause() external;

    function unpause(address) external;
}

/// @title UnPauseSuperchainConfig
contract UnPauseSuperchainConfigTemplate is L2TaskBase {
    using stdToml for string;

    // /// @notice Mapping of chain ID to configuration for the task.
    //
    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "securityCouncilU16";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites()
        internal
        pure
        override
        returns (string[] memory)
    {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "securityCouncilU16";
        storageWrites[1] = safeAddressString();
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(
        string memory taskConfigFilePath
    ) internal override {
        super._templateSetup(taskConfigFilePath);
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        // Load the DeputyGuardianModule contract.
        IDeputyGuardianModuleU16 dpm = IDeputyGuardianModuleU16(
            0xEB4e480de616FEDe3D03597e42c013282BF9bEcF
        );
        dpm.unpause(address(0)); // Unpause the SuperchainConfig contract through the DeputyGuardianModule.
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(
        VmSafe.AccountAccess[] memory,
        Action[] memory
    ) internal view override {
        // Validate that the SuperchainConfig contract is unpaused.
        // SuperchainAddressRegistry.ChainInfo[]
        //     memory chains = superchainAddrRegistry.getChains();
        // ISuperchainConfig sc = ISuperchainConfig(
        //     (
        //         superchainAddrRegistry.getAddress(
        //             "SuperchainConfig",
        //             chains[0].chainId
        //         )
        //     )
        // );
        // IOptimismPortal2 portal2 = IOptimismPortal2(
        //     payable(
        //         superchainAddrRegistry.getAddress(
        //             "OptimismPortalProxy",
        //             chains[0].chainId
        //         )
        //     )
        // );
        // assertEq(
        //     portal2.paused(),
        //     false,
        //     "ERR101: OptimismPortal2 should be unpaused."
        // );
        // assertEq(
        //     sc.paused(),
        //     false,
        //     "ERR102: SuperchainConfig should be unpaused."
        // );
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory codeExceptions = new address[](0);
        return codeExceptions;
    }
}
