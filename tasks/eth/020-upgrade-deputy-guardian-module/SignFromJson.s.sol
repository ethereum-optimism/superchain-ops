// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {OptimismPortal2, IDisputeGame} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {ModuleManager} from "safe-contracts/base/ModuleManager.sol";

interface IDeputyGuardianModuleFetcher {
    function deputyGuardian() external view returns (address deputyGuardian_);
    function safe() external view returns (address safe_);
    function superchainConfig() external view returns (address superchainConfig_);
    function version() external view returns (string memory);
}

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    address constant SENTINEL_MODULE = address(0x1);

    // Chains for this task.
    string constant l1ChainName = "mainnet";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    GnosisSafe foundationOperationsSafe = GnosisSafe(payable(0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A));

    GnosisSafe expectedGuardian = GnosisSafe(payable(0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2));
    address expectedDeputyGuardianModule = vm.envAddress("DEPUTY_GUARDIAN_MODULE");
    address expectedLivenessGuard = 0x24424336F04440b1c28685a38303aC33C9D14a25;

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        address[] memory securityCouncilSafeOwners = securityCouncilSafe.getOwners();
        address[] memory shouldHaveCodeExceptions = new address[](securityCouncilSafeOwners.length);

        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            shouldHaveCodeExceptions[i] = securityCouncilSafeOwners[i];
        }

        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](4);
        allowed[0] = proxies.OptimismPortal;
        allowed[1] = vm.envAddress("OWNER_SAFE");
        allowed[2] = expectedLivenessGuard;
        allowed[3] = address(expectedGuardian);
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkDeputyGuardianModule();

        console.log("All assertions passed!");
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/configs/${l1ChainName}/${l2ChainName}.toml
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory chainConfig;

        // Read chain-specific config toml file
        string memory path =
            string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/", l2ChainName, ".toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        // Read the chain-specific OptimismPortalProxy address
        _proxies.OptimismPortal = stdToml.readAddress(chainConfig, "$.addresses.OptimismPortalProxy");

        path = string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        _proxies.SuperchainConfig = stdToml.readAddress(chainConfig, "$.superchain_config_addr");
    }

    function checkDeputyGuardianModule() internal view {
        console.log("Running assertions on the DeputyGuardianModule");

        (address[] memory modules, address nextModule) =
            ModuleManager(expectedGuardian).getModulesPaginated(SENTINEL_MODULE, 1);
        address deputyGuardianModuleAddr = modules[0];

        require(modules.length == 1, "checkDeputyGuardianModule-40");
        require(address(deputyGuardianModuleAddr) == expectedDeputyGuardianModule, "checkDeputyGuardianModule-60");
        require(nextModule == SENTINEL_MODULE, "checkDeputyGuardianModule-80");

        IDeputyGuardianModuleFetcher deputyGuardianModule = IDeputyGuardianModuleFetcher(deputyGuardianModuleAddr);
        require(deputyGuardianModule.version().eq("2.0.0"), "checkDeputyGuardianModule-100");
        require(deputyGuardianModule.safe() == address(expectedGuardian), "checkDeputyGuardianModule-200");
        require(
            deputyGuardianModule.deputyGuardian() == address(foundationOperationsSafe), "checkDeputyGuardianModule-300"
        );
        require(
            deputyGuardianModule.superchainConfig() == address(proxies.SuperchainConfig),
            "checkDeputyGuardianModule-400"
        );

        require(
            ModuleManager(expectedGuardian).isModuleEnabled(expectedDeputyGuardianModule), "checkDeputyGuardianModule-500"
        );
    }
}
