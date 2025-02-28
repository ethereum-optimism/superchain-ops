// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {IDeputyPauseModule} from "@eth-optimism-bedrock/interfaces/safe/IDeputyPauseModule.sol";
import {VmSafe} from "forge-std/Vm.sol";

import "forge-std/Test.sol";

import {L2TaskBase} from "src/improvements/tasks/MultisigTask.sol";
import {ModuleManager} from "lib/safe-contracts/contracts/base/ModuleManager.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";

/// @notice Template contract for enabling the DeputyPauseModule in a Gnosis Safe
contract EnableDeputyPauseModuleTemplate is L2TaskBase {
    using AccountAccessParser for *;
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

    /// @notice Returns the safe address string identifier
    /// @return The string "DeputyPauseSafe"
    function safeAddressString() public pure override returns (string memory) {
        return _SAFE_ADDRESS;
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites;

        storageWrites = new string[](1);
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

    /// @notice Builds the action for enabling the module in the Safe
    function _build() internal override {
        ModuleManager(parentMultisig).enableModule(newModule);
    }

    /// @notice Validates that the module was enabled correctly.
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory) internal view override {
        AddressRegistry.ChainInfo[] memory chains = addrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            _validatePerChain(chainId, accountAccesses);
        }
    }

    /// @notice Validates that the module was enabled correctly for a given chain.
    /// @param chainId The chain ID of the chain to validate
    /// @param accountAccess the list of account accesses performed by this task
    function _validatePerChain(uint256 chainId, VmSafe.AccountAccess[] memory accountAccess) internal view {
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

        IDeputyPauseModule deputyGuardianModule = IDeputyPauseModule(newModule);
        assertEq(deputyGuardianModule.version(), "1.0.0-beta.2", "Deputy Guardian Module version not correct");
        assertEq(
            address(deputyGuardianModule.foundationSafe()), parentMultisig, "Deputy Guardian safe pointer not correct"
        );
        assertEq(
            address(deputyGuardianModule.superchainConfig()),
            addrRegistry.getAddress("SuperchainConfig", chainId),
            "Superchain config address not correct"
        );

        bytes32 moduleSlot = keccak256(abi.encode(newModule, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL_MODULE, MODULE_MAPPING_STORAGE_OFFSET));

        bool moduleWriteFound;

        address[] memory uniqueWrites = accountAccess.getUniqueWrites();
        assertEq(uniqueWrites.length, 1, "should only write to foundation ops safe");
        assertEq(uniqueWrites[0], parentMultisig, "should only write to foundation ops safe address");

        AccountAccessParser.StateDiff[] memory accountWrites = accountAccess.getStateDiffFor(parentMultisig);

        for (uint256 i = 0; i < accountWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = accountWrites[i];
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
                    sentinelModuleValue, bytes32(uint256(uint160(newModule))), "sentinel does not point to new module"
                );

                moduleWriteFound = true;
            }
        }

        /// module write must be found, else revert
        assertTrue(moduleWriteFound, "Module write not found");
    }

    /// @notice No code exceptions for this template
    function getCodeExceptions() internal view override returns (address[] memory) {}
}
