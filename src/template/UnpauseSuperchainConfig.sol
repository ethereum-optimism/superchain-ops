// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {ISuperchainConfig} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/ISuperchainConfig.sol";
import {
    IDeputyGuardianModule,
    IOptimismPortal2
} from "lib/optimism/packages/contracts-bedrock/interfaces/safe/IDeputyGuardianModule.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @title UnpauseSuperchainConfig before contract version 4.0.0. After version 4.0.0 please refer to the template UnpauseSuperchainConfigV400.
contract UnpauseSuperchainConfig is L2TaskBase {
    using stdToml for string;

    // /// @notice Mapping of chain ID to configuration for the task.
    //
    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "FoundationOperationsSafe";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "SuperchainConfig";
        storageWrites[1] = safeAddressString();
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build(address) internal override {
        // Load the DeputyGuardianModule contract.
        IDeputyGuardianModule dgm = IDeputyGuardianModule(superchainAddrRegistry.get("DeputyGuardianModule"));
        dgm.unpause(); // Unpause the SuperchainConfig contract through the DeputyGuardianModule.
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        // Validate that the SuperchainConfig contract is unpaused.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        ISuperchainConfig sc =
            ISuperchainConfig((superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId)));
        IOptimismPortal2 portal2 =
            IOptimismPortal2(payable(superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[0].chainId)));
        assertEq(portal2.paused(), false, "ERR101: OptimismPortal2 should be unpaused.");
        assertEq(sc.paused(), false, "ERR102: SuperchainConfig should be unpaused.");
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal pure override returns (address[] memory) {}
}
