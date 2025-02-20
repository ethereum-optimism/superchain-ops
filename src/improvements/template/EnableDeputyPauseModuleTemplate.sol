// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";

import "forge-std/Test.sol";

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
    string constant _SAFE_ADDRESS = "FoundationOperationSafe";

    /// @notice Gnosis Safe Sentinel Module address
    address internal constant SENTINEL_MODULE = address(0x1);

    /// @notice Gnosis Safe Module Mapping Storage Offset
    uint256 public constant MODULE_MAPPING_STORAGE_OFFSET = 1;

    /// @notice Gnosis Safe Module Nonce Storage Offset
    bytes32 public constant NONCE_STORAGE_OFFSET = bytes32(uint256(5));

    /// @notice Chain ID of the chain being modified
    uint256 public immutable CHAIN_ID;

    /// @notice Mainnet Chain ID
    uint256 public immutable MAINNET_CHAIN_ID;

    constructor() {
        CHAIN_ID = block.chainid;
        MAINNET_CHAIN_ID = getChain("mainnet").chainId;
    }

    /// @notice Returns the safe address string identifier
    /// @return The string "DeputyPauseSafe"
    function safeAddressString() public pure override returns (string memory) {
        return _SAFE_ADDRESS;
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal view override returns (string[] memory) {
        // if mainnet is the chain being modified, this task will write to the
        // LivenessGuard contract
        // hardcode the chain id for mainnet to avoid making the function
        // mutative and overriding the pure keyword

        // this code does not work:
        //   if (block.chainid == getChain("mainnet").chainId) {
        // because the getChain function writes to storage, making this
        // function mutative
        // Instead, we write the chain id for mainnet in the constructor

        string[] memory storageWrites;

        if (CHAIN_ID == MAINNET_CHAIN_ID) {
            storageWrites = new string[](2);
            storageWrites[1] = "LivenessGuard";
        } else {
            // otherwise, we only need to write to the Safe
            storageWrites = new string[](1);
        }

        storageWrites[0] = _SAFE_ADDRESS;

        return storageWrites;
    }

    /// @notice Sets up the template with module configuration from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        string memory file = vm.readFile(taskConfigFilePath);
        newModule = vm.parseTomlAddress(file, ".newModule");
        assertNotEq(newModule.code.length, 0, "new module must have code");

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
        (address[] memory modules, address nextModule) =
            ModuleManager(parentMultisig).getModulesPaginated(SENTINEL_MODULE, 100);

        assertTrue(ModuleManager(parentMultisig).isModuleEnabled(newModule), "Module not enabled");
        assertEq(nextModule, SENTINEL_MODULE, "Next module not correct");

        bool moduleFound;
        for (uint256 i = 0; i < modules.length; i++) {
            if (modules[i] == newModule) {
                moduleFound = true;
            }
        }
        assertTrue(moduleFound, "Module not found in new modules list");

        IDeputyGuardianModuleFetcher deputyGuardianModule = IDeputyGuardianModuleFetcher(newModule);
        assertEq(deputyGuardianModule.version(), "1.0.0-beta.2", "Deputy Guardian Module version not correct");
        assertEq(deputyGuardianModule.foundationSafe(), parentMultisig, "Deputy Guardian safe pointer not correct");
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

        (address[] memory modules,) = ModuleManager(parentMultisig).getModulesPaginated(SENTINEL_MODULE, 100);

        bytes32 moduleSlot = keccak256(abi.encode(newModule, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL_MODULE, MODULE_MAPPING_STORAGE_OFFSET));

        bool moduleWriteFound;

        for (uint256 i; i < accountAccesses.length; i++) {
            VmSafe.AccountAccess memory accountAccess = accountAccesses[i];
            for (uint256 j; j < accountAccess.storageAccesses.length; j++) {
                VmSafe.StorageAccess memory storageAccess = accountAccess.storageAccesses[j];
                if (!storageAccess.isWrite) continue; // Skip SLOADs.
                if (storageAccess.isWrite && storageAccess.account == parentMultisig) {
                    assertTrue(
                        storageAccess.slot == NONCE_STORAGE_OFFSET || storageAccess.slot == moduleSlot
                            || storageAccess.slot == sentinelSlot,
                        "Only nonce and module slot should be updated on upgrade controller multisig"
                    );

                    if (storageAccess.slot == moduleSlot) {
                        assertEq(
                            address(uint160(uint256(storageAccess.newValue))),
                            modules.length >= 2 ? modules[1] : SENTINEL_MODULE,
                            "new module not correct"
                        );

                        bytes32 sentinelModuleValue = vm.load(parentMultisig, sentinelSlot);
                        assertEq(
                            sentinelModuleValue,
                            bytes32(uint256(uint160(newModule))),
                            "sentinel does not point to new module"
                        );

                        moduleWriteFound = true;
                    }
                }
            }
        }

        /// module write must be found, else revert
        assertTrue(moduleWriteFound, "Module write not found");
    }
}

interface IDeputyGuardianModuleFetcher {
    function deputyGuardian() external view returns (address);
    function foundationSafe() external view returns (address);
    function superchainConfig() external view returns (address);
    function version() external view returns (string memory);
}
