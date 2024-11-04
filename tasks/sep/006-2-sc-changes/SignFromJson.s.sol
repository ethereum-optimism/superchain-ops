// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {L1StandardBridge} from "@eth-optimism-bedrock/src/L1/L1StandardBridge.sol";
import {L2OutputOracle} from "@eth-optimism-bedrock/src/L1/L2OutputOracle.sol";
import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
import {OptimismPortal} from "@eth-optimism-bedrock/src/L1/OptimismPortal.sol";
import {L1CrossDomainMessenger} from "@eth-optimism-bedrock/src/L1/L1CrossDomainMessenger.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/src/L1/L1ERC721Bridge.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {ModuleManager} from "safe-contracts/base/ModuleManager.sol";

// Interfaces of the new contracts we need to check.
interface ILivenessModuleFetcher {
    function fallbackOwner() external view returns (address fallbackOwner_);
    function getRequiredThreshold(uint256 _numOwners) external view returns (uint256 threshold_);
    function livenessGuard() external view returns (address livenessGuard_);
    function livenessInterval() external view returns (uint256 livenessInterval_);
    function minOwners() external view returns (uint256 minOwners_);
    function safe() external view returns (address safe_);
    function thresholdPercentage() external view returns (uint256 thresholdPercentage_);
    function version() external view returns (string memory);
}

interface ILivenessGuardFetcher {
    function lastLive(address) external view returns (uint256);
    function safe() external view returns (address safe_);
    function version() external view returns (string memory);
}

interface IDeputyGuardianModuleFetcher {
    function deputyGuardian() external view returns (address deputyGuardian_);
    function safe() external view returns (address safe_);
    function superchainConfig() external view returns (address superchainConfig_);
    function version() external view returns (string memory);
}

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    address constant SENTINEL_MODULE = address(0x1);
    bytes32 constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;
    bytes32 constant GUARDIAN_SLOT = bytes32(uint256(keccak256("superchainConfig.guardian")) - 1);

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Properties we want to verify.
    uint256 constant expectedGuardLivenessInterval = 62899200;
    uint256 constant expectedGuardMinOwners = 2;
    uint256 constant expectedGuardThresholdPercentage = 30;

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    GnosisSafe expectedGuardian = GnosisSafe(payable(0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E));
    GnosisSafe foundationUpgradesSafe = GnosisSafe(payable(0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B));
    GnosisSafe foundationOperationsSafe = GnosisSafe(payable(0x837DE453AD5F21E89771e3c06239d8236c0EFd5E));
    GnosisSafe proxyAdminOwnerSafe = GnosisSafe(payable(0x1Eb2fFc903729a0F03966B917003800b145F56E2));

    // Contracts we need to check, which are not in the superchain registry.
    address expectedDeputyGuardianModule = 0x4220C5deD9dC2C8a8366e684B098094790C72d3c;
    address expectedLivenessModule = 0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e;
    address expectedLivenessGuard = 0xc26977310bC89DAee5823C2e2a73195E85382cC7;

    // All L1 proxy addresses.
    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function _addGenericOverrides() internal view override returns (SimulationStateOverride memory override_) {
        // If `runJson` was the method invoked, this is the live execution and we do not want to
        // apply any overrides. Otherwise, this is a simulation and we want to apply overrides to
        // behave as if 006-1 was executed.
        if (msg.sig != this.runJson.selector) {
            SimulationStorageOverride[] memory overrides = new SimulationStorageOverride[](1);
            overrides[0] = SimulationStorageOverride({
                key: GUARDIAN_SLOT,
                value: bytes32(uint256(uint160(address(expectedGuardian))))
            });
            override_ = SimulationStateOverride({contractAddress: proxies.SuperchainConfig, overrides: overrides});
        }
    }

    function checkSemvers() internal view {
        console.log("Running assertions on the semvers");

        // These are the expected semvers based on the `op-contracts/v1.4.0-rc.4` release.
        // https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.4.0-rc.4
        require(ISemver(proxies.L1CrossDomainMessenger).version().eq("2.3.0"), "semver-100");
        require(ISemver(proxies.L1StandardBridge).version().eq("2.1.0"), "semver-200");
        require(ISemver(proxies.DisputeGameFactory).version().eq("1.0.0"), "semver-300");
        require(ISemver(proxies.OptimismMintableERC20Factory).version().eq("1.9.0"), "semver-400");
        require(ISemver(proxies.OptimismPortal).version().eq("3.10.0"), "semver-500");
        require(ISemver(proxies.SystemConfig).version().eq("2.2.0"), "semver-600");
        require(ISemver(proxies.L1ERC721Bridge).version().eq("2.1.0"), "semver-700");
        require(ISemver(proxies.ProtocolVersions).version().eq("1.0.0"), "semver-800");
        require(ISemver(proxies.SuperchainConfig).version().eq("1.1.0"), "semver-900");
    }

    /// @notice Asserts that the SuperchainConfig is setup correctly
    function checkSuperchainConfig() internal view {
        console.log("Running assertions on the SuperchainConfig");

        require(proxies.SuperchainConfig.code.length != 0, "7100");
        require(EIP1967Helper.getImplementation(proxies.SuperchainConfig).code.length != 0, "7101");

        SuperchainConfig superchainConfigToCheck = SuperchainConfig(proxies.SuperchainConfig);
        require(superchainConfigToCheck.guardian() == address(expectedGuardian), "7200");
        require(superchainConfigToCheck.guardian().code.length != 0, "7250");
        require(superchainConfigToCheck.paused() == false, "7300");
    }

    function checkLivenessModule() internal view {
        console.log("Running assertions on the LivenessModule");

        (address[] memory modules, address nextModule) =
            ModuleManager(securityCouncilSafe).getModulesPaginated(SENTINEL_MODULE, 1);
        address livenessModuleAddr = modules[0];

        require(modules.length == 1, "checkLivenessModule-20");
        require(address(livenessModuleAddr) == expectedLivenessModule, "checkLivenessModule-40");
        require(nextModule == SENTINEL_MODULE, "checkLivenessModule-60");

        ILivenessModuleFetcher livenessModule = ILivenessModuleFetcher(livenessModuleAddr);
        require(livenessModule.version().eq("1.2.0"), "checkLivenessModule-80");
        require(livenessModule.safe() == address(securityCouncilSafe), "checkLivenessModule-100");
        require(livenessModule.livenessGuard() == address(expectedLivenessGuard), "checkLivenessModule-200");
        require(livenessModule.livenessInterval() == expectedGuardLivenessInterval, "checkLivenessModule-300");
        require(livenessModule.minOwners() == expectedGuardMinOwners, "checkLivenessModule-400");
        require(livenessModule.thresholdPercentage() == expectedGuardThresholdPercentage, "checkLivenessModule-500");
        require(livenessModule.fallbackOwner() == address(foundationUpgradesSafe), "checkLivenessModule-600");
    }

    function checkLivenessGuard() internal view {
        console.log("Running assertions on the LivenessGuard");

        bytes32 _livenessGuard = vm.load(address(securityCouncilSafe), GUARD_STORAGE_SLOT);
        address livenessGuardAddr = address(uint160(uint256(_livenessGuard)));
        require(address(livenessGuardAddr) == expectedLivenessGuard, "checkLivenessGuard-60");

        ILivenessGuardFetcher livenessGuard = ILivenessGuardFetcher(livenessGuardAddr);
        require(livenessGuard.version().eq("1.0.0"), "checkLivenessGuard-80");
        require(livenessGuard.safe() == address(securityCouncilSafe), "checkLivenessGuard-100");
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
        require(deputyGuardianModule.version().eq("1.1.0"), "checkDeputyGuardianModule-100");
        require(deputyGuardianModule.safe() == address(expectedGuardian), "checkDeputyGuardianModule-200");
        require(
            deputyGuardianModule.deputyGuardian() == address(foundationOperationsSafe), "checkDeputyGuardianModule-100"
        );
        require(
            deputyGuardianModule.superchainConfig() == address(proxies.SuperchainConfig),
            "checkDeputyGuardianModule-300"
        );
    }

    function checkProxyAdminOwnerSafe() internal {
        vm.prank(address(0));
        address proxyAdmin = Proxy(payable(address(proxies.SuperchainConfig))).admin();

        address proxyAdminOwner = ProxyAdmin(proxyAdmin).owner();
        require(proxyAdminOwner == address(proxyAdminOwnerSafe), "checkProxyAdminOwnerSafe-260");

        address[] memory owners = proxyAdminOwnerSafe.getOwners();
        require(owners.length == 2, "checkProxyAdminOwnerSafe-270");
        require(proxyAdminOwnerSafe.isOwner(address(foundationUpgradesSafe)), "checkProxyAdminOwnerSafe-300");
        require(proxyAdminOwnerSafe.isOwner(address(securityCouncilSafe)), "checkProxyAdminOwnerSafe-400");
    }

    function checkOwnershipModel() internal {
        console.log("Running assertions on the OwnershipModel");
        // After this playbook is executed, the resulting ownership model of the protocol should
        // look like this:
        //   1. The Guardian on the superchain config is the 1/1 Security Council Safe.
        //   2. The 1/1 SC Safe has the Deputy Guardian Module installed with the Foundation
        //     Operations Safe as the Deputy Guardian.
        //   3. The main Security Council Safe has the Liveness Module and Liveness Guard installed.
        //   4. The L1 ProxyAdmin owner is a 2/2 Safe between the Security Council Safe and the
        //     Foundation Upgrades Safe.
        address guardian = SuperchainConfig(proxies.SuperchainConfig).guardian();

        // Check 1. The Guardian on the superchain config is the 1/1 Security Council Safe.
        require(guardian == address(expectedGuardian), "checkOwnershipModel-100");
        address[] memory securityCouncilGuardianOwners = GnosisSafe(payable(guardian)).getOwners();
        require(securityCouncilGuardianOwners.length == 1, "checkOwnershipModel-200");
        require(securityCouncilGuardianOwners[0] == address(securityCouncilSafe), "checkOwnershipModel-300");

        // Check 2. The 1/1 SC Safe has the Deputy Guardian Module installed with the Foundation
        // Operations Safe as the Deputy Guardian.
        checkDeputyGuardianModule();

        // Check 3. The main Security Council Safe has the Liveness Module and Liveness Guard installed.
        checkLivenessModule();
        checkLivenessGuard();

        // Check 4. The L1 ProxyAdmin owner is a 2/2 Safe between the Security Council Safe and the
        // Foundation Upgrades Safe.
        checkProxyAdminOwnerSafe();
    }

    function checkStateDiff(Vm.AccountAccess[] memory accountAccesses) internal view override {
        super.checkStateDiff(accountAccesses);

        for (uint256 i; i < accountAccesses.length; i++) {
            Vm.AccountAccess memory accountAccess = accountAccesses[i];

            // Assert that only the expected accounts have been written to.
            for (uint256 j; j < accountAccess.storageAccesses.length; j++) {
                Vm.StorageAccess memory storageAccess = accountAccess.storageAccesses[j];
                if (storageAccess.isWrite) {
                    address account = storageAccess.account;
                    // Only state changes to the Safe's are expected.
                    require(
                        account == address(expectedGuardian) || account == address(securityCouncilSafe), "state-100"
                    );
                }
            }
        }
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkSemvers();
        checkSuperchainConfig();
        checkOwnershipModel();

        console.log("All assertions passed!");
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Safe owners will appear in storage in the LivenessGuard when added, and they are allowed
        // to have code AND to have no code.
        address[] memory securityCouncilSafeOwners = securityCouncilSafe.getOwners();

        // To make sure we probably handle all signers whether or not they have code, first we count
        // the number of signers that have no code.
        uint256 numberOfSafeSignersWithNoCode;
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                numberOfSafeSignersWithNoCode++;
            }
        }

        // Then we extract those EOA addresses into a dedicated array.
        uint256 trackedSignersWithNoCode;
        address[] memory safeSignersWithNoCode = new address[](numberOfSafeSignersWithNoCode);
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                safeSignersWithNoCode[trackedSignersWithNoCode] = securityCouncilSafeOwners[i];
                trackedSignersWithNoCode++;
            }
        }

        // And finally, we set the Safe signer exceptions.
        address[] memory shouldHaveCodeExceptions = new address[](numberOfSafeSignersWithNoCode);
        for (uint256 i = 0; i < safeSignersWithNoCode.length; i++) {
            shouldHaveCodeExceptions[i] = safeSignersWithNoCode[i];
        }

        return shouldHaveCodeExceptions;
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/extra/addresses/sepolia/op.json
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory addressesJson;

        // Read addresses json
        string memory path = string.concat(
            "/lib/superchain-registry/superchain/extra/addresses/", l1ChainName, "/", l2ChainName, ".json"
        );
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        _proxies.L1CrossDomainMessenger = stdJson.readAddress(addressesJson, "$.L1CrossDomainMessengerProxy");
        _proxies.L1StandardBridge = stdJson.readAddress(addressesJson, "$.L1StandardBridgeProxy");
        _proxies.DisputeGameFactory = stdJson.readAddress(addressesJson, "$.DisputeGameFactoryProxy");
        _proxies.OptimismMintableERC20Factory =
            stdJson.readAddress(addressesJson, "$.OptimismMintableERC20FactoryProxy");
        _proxies.OptimismPortal = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
        _proxies.OptimismPortal2 = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
        _proxies.SystemConfig = stdJson.readAddress(addressesJson, "$.SystemConfigProxy");
        _proxies.L1ERC721Bridge = stdJson.readAddress(addressesJson, "$.L1ERC721BridgeProxy");

        // Read superchain.yaml
        string[] memory inputs = new string[](4);
        inputs[0] = "yq";
        inputs[1] = "-o";
        inputs[2] = "json";
        inputs[3] = string.concat("lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.yaml");

        addressesJson = string(vm.ffi(inputs));

        _proxies.ProtocolVersions = stdJson.readAddress(addressesJson, "$.protocol_versions_addr");
        _proxies.SuperchainConfig = stdJson.readAddress(addressesJson, "$.superchain_config_addr");
    }
}
