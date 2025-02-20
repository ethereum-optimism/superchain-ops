// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {LibString} from "solady/utils/LibString.sol";
import {IDeputyPauseModule} from "@eth-optimism-bedrock/interfaces/safe/IDeputyPauseModule.sol";
import {Types} from "@eth-optimism-bedrock/scripts/libraries/Types.sol";
import {ModuleManager} from "safe-contracts/base/ModuleManager.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdToml} from "forge-std/StdToml.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    /// @notice L1 chain name for this task.
    string constant l1ChainName = "sepolia";

    /// @notice Sentinel module address.
    address constant SENTINEL_MODULE = address(0x1);

    /// @notice Address of the Security Council Safe.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("SECURITY_COUNCIL_GUARDIAN_SAFE")));

    /// @notice Address of the Foundation Operations Safe.
    GnosisSafe foundationOperationsSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_OPERATIONS_SAFE")));

    /// @notice Expected address of the DeputyPauseModule contract.
    address expectedDeputyPauseModule = vm.envAddress("DEPUTY_PAUSE_MODULE");

    /// @notice Expected address of the Pause Deputy.
    address expectedPauseDeputy = vm.envAddress("PAUSE_DEPUTY");

    /// @notice System contracts.
    Types.ContractSet proxies;

    /// @notice Sets up the script.
    function setUp() public {
        proxies = _getContractSet();
    }

    /// @notice Returns addresses that are allowed to not have any code.
    /// @return allowed_ The addresses that are allowed to not have any code.
    function getCodeExceptions() internal pure override returns (address[] memory allowed_) {
        allowed_ = new address[](0);
    }

    /// @notice Returns addresses that are allowed to access storage.
    /// @return allowed_ The addresses that are allowed to access storage.
    function getAllowedStorageAccess() internal view override returns (address[] memory allowed_) {
        allowed_ = new address[](1);
        allowed_[0] = address(foundationOperationsSafe);
    }

    /// @notice Checks the correctness of the execution.
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkDeputyPauseModule();

        console.log("All assertions passed!");
    }

    /// @notice Reads contract addresses from config files.
    /// @return _proxies The contract addresses.
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory path =
            string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            _proxies.SuperchainConfig = stdToml.readAddress(data, "$.superchain_config_addr");
        } catch {
            revert(string.concat("Failed to read ", path));
        }
    }

    /// @notice Checks that the DeputyPauseModule is correctly configured.
    function checkDeputyPauseModule() internal view {
        console.log("Running assertions on the DeputyPauseModule");

        // Grab modules from the Safe.
        (address[] memory modules, address nextModule) =
            ModuleManager(foundationOperationsSafe).getModulesPaginated(SENTINEL_MODULE, 5);

        // Should only have one module.
        require(modules.length == 1, "checkDeputyPauseModule-40");

        // First module should be the DeputyPauseModule.
        IDeputyPauseModule dpm = IDeputyPauseModule(modules[0]);
        require(address(dpm) == expectedDeputyPauseModule, "checkDeputyPauseModule-60");

        // Next module should be the sentinel module.
        require(nextModule == SENTINEL_MODULE, "checkDeputyPauseModule-80");

        // DeputyPauseModule should be enabled.
        require(ModuleManager(foundationOperationsSafe).isModuleEnabled(address(dpm)), "checkDeputyGuardianModule-100");

        // DeputyPauseModule.foundationSafe() should be the foundationOperationsSafe.
        require(address(dpm.foundationSafe()) == address(foundationOperationsSafe), "checkDeputyPauseModule-120");

        // DeputyPauseModule.superchainConfig() should be the SuperchainConfig.
        require(address(dpm.superchainConfig()) == address(proxies.SuperchainConfig), "checkDeputyPauseModule-140");

        // DeputyPauseModule.deputy() should be the expectedPauseDeputy.
        require(dpm.deputy() == expectedPauseDeputy, "checkDeputyPauseModule-160");

        // DeputyPauseModule.deputyGuardianModule() should be the DeputyGuardianModule.
        (address[] memory modules2,) = ModuleManager(securityCouncilSafe).getModulesPaginated(SENTINEL_MODULE, 1);
        require(address(dpm.deputyGuardianModule()) == modules2[0], "checkDeputyPauseModule-180");
    }
}
