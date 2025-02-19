// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {ModuleManager} from "lib/safe-contracts/contracts/base/ModuleManager.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";

/// @title EnableDeputyPauseModuleTemplate
/// @notice Template contract for enabling a module in a Gnosis Safe
contract EnableDeputyPauseModuleTemplate is MultisigTask {
    using stdStorage for StdStorage;

    /// @notice Module configuration loaded from TOML
    address public newModule;

    /// @notice Constant safe address string identifier
    string constant _SAFE_ADDRESS = "DeputyPauseSafe";

    /// @notice Gnosis Safe Sentinel Module address
    address internal constant SENTINEL_MODULE = address(0x1);

    /// @notice Returns the safe address string identifier
    /// @return The string "DeputyPauseSafe"
    function safeAddressString() public pure override returns (string memory) {
        return _SAFE_ADDRESS;
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = _SAFE_ADDRESS;
        return storageWrites;
    }

    /// @notice Sets up the template with module configuration from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        string memory file = vm.readFile(taskConfigFilePath);
        newModule = vm.parseTomlAddress(file, ".newModule");

        // only allow one chain to be modified at a time with this template
        AddressRegistry.ChainInfo[] memory _chains =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".l2chains"), (AddressRegistry.ChainInfo[]));

        assertEq(_chains.length, 1, "Must specify exactly one chain id to enable deputy pause module for");
    }

    /// @notice Empty implementation as specified
    /// @param chainId The ID of the L2 chain
    function _buildPerChain(uint256 chainId) internal override {}

    /// @notice Builds the action for enabling the module in the Safe
    function _buildSingle() internal override {
        ModuleManager(parentMultisig).enableModule(newModule);
    }

    /// @notice Validates that the module was enabled correctly
    /// @param chainId The ID of the L2 chain to validate
    function _validate(uint256 chainId) internal view override {
        address safe = addrRegistry.getAddress(_SAFE_ADDRESS, chainId);
        (address[] memory modules, address nextModule) = ModuleManager(safe).getModulesPaginated(SENTINEL_MODULE, 1);

        assertTrue(ModuleManager(safe).isModuleEnabled(newModule), "Module not enabled");
        assertEq(nextModule, SENTINEL_MODULE, "Next module not correct");
        assertEq(modules[0], newModule, "Module not enabled");
        assertEq(modules.length, 1, "Should only be a single module");

        IDeputyGuardianModuleFetcher deputyGuardianModule = IDeputyGuardianModuleFetcher(newModule);
        assertEq(deputyGuardianModule.version(), "1.0.0-beta.2", "Deputy Guardian Module version not correct");
        assertEq(deputyGuardianModule.safe(), safe, "Deputy Guardian safe pointer not correct");
        assertEq(
            deputyGuardianModule.superchainConfig(),
            addrRegistry.getAddress("SuperchainConfig", chainId),
            "Superchain config address not correct"
        );
    }

    /// @notice No code exceptions for this template
    function getCodeExceptions() internal view override returns (address[] memory) {}

    /// @notice helper function that can be overridden by template contracts to
    /// check the state changes applied by the task. This function can check
    /// that only the nonce changed in the parent multisig when executing a task
    /// by checking the slot and address where the slot changed.
    function checkStateDiff(VmSafe.AccountAccess[] memory accountAccesses) internal override {
        super.checkStateDiff(accountAccesses);

        uint256 moduleSlot = stdstore.target(parentMultisig).sig(ModuleManager.getModulesPaginated.selector).with_calldata(
            abi.encode(SENTINEL_MODULE, 1)
        ).find();

        for (uint256 i; i < accountAccesses.length; i++) {
            VmSafe.AccountAccess memory accountAccess = accountAccesses[i];
            for (uint256 j; j < accountAccess.storageAccesses.length; j++) {
                VmSafe.StorageAccess memory storageAccess = accountAccess.storageAccesses[j];
                if (!storageAccess.isWrite) continue; // Skip SLOADs.
                if (storageAccess.isWrite && storageAccess.account == parentMultisig) {
                    assertTrue(
                        storageAccess.slot == 0 || storageAccess.slot == bytes32(moduleSlot),
                        "Only nonce and module slot should be updated on upgrade controller multisig"
                    );
                }
            }
        }
    }
}

interface IDeputyGuardianModuleFetcher {
    function deputyGuardian() external view returns (address deputyGuardian_);
    function safe() external view returns (address safe_);
    function superchainConfig() external view returns (address superchainConfig_);
    function version() external view returns (string memory);
}
