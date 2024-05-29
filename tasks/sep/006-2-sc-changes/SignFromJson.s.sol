// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Constants, ResourceMetering} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {L1StandardBridge} from "@eth-optimism-bedrock/src/L1/L1StandardBridge.sol";
import {L2OutputOracle} from "@eth-optimism-bedrock/src/L1/L2OutputOracle.sol";
import {ProtocolVersion, ProtocolVersions} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
import {OptimismPortal} from "@eth-optimism-bedrock/src/L1/OptimismPortal.sol";
import {L1CrossDomainMessenger} from "@eth-optimism-bedrock/src/L1/L1CrossDomainMessenger.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/src/L1/L1ERC721Bridge.sol";
import {AddressManager} from "@eth-optimism-bedrock/src/legacy/AddressManager.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {ModuleManager} from "safe-contracts/base/ModuleManager.sol";

// Interface used to read various data from contracts. This is an aggregation of methods from
// various protocol contracts for simplicity, and does not map to the full ABI of any single contract.
interface IFetcher {
    function overhead() external returns (uint256); // SystemConfig
    function scalar() external returns (uint256); // SystemConfig
    function guardian() external returns (address); // SuperchainConfig
    function L2_BLOCK_TIME() external returns (uint256); // L2OutputOracle
    function SUBMISSION_INTERVAL() external returns (uint256); // L2OutputOracle
    function FINALIZATION_PERIOD_SECONDS() external returns (uint256); // L2OutputOracle
    function startingTimestamp() external returns (uint256); // L2OutputOracle
    function startingBlockNumber() external returns (uint256); // L2OutputOracle
    function owner() external returns (address); // ProtocolVersions
    function required() external returns (uint256); // ProtocolVersions
    function recommended() external returns (uint256); // ProtocolVersions
}

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

    address internal constant SENTINEL_MODULE = address(0x1);
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(0xf64bc17485f0B4Ea5F06A96514182FC4cB561977));
    GnosisSafe guardianSafe = GnosisSafe(payable(0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E));
    GnosisSafe foundationUpgradesSafe = GnosisSafe(payable(0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B));
    GnosisSafe foundationOperationsSafe = GnosisSafe(payable(0x837DE453AD5F21E89771e3c06239d8236c0EFd5E));

    // Contracts we need to check, which are not in the superchain registry
    address expectedDeputyGuardianModule = 0x4220C5deD9dC2C8a8366e684B098094790C72d3c;
    address expectedLivenessModule = 0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e;
    address expectedLivenessGuard = 0xc26977310bC89DAee5823C2e2a73195E85382cC7;

    // We fetch these and compare them to the expected values.
    IDeputyGuardianModuleFetcher deputyGuardianModule;
    ILivenessGuardFetcher livenessGuard;
    ILivenessModuleFetcher livenessModule;

    // Known EOAs to exclude from safety checks.
    address constant l2OutputOracleProposer = 0x49277EE36A024120Ee218127354c4a3591dc90A9; // cast call $L2OO "PROPOSER()(address)"
    address constant l2OutputOracleChallenger = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant systemConfigOwner = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant batchSenderAddress = 0x8F23BB38F531600e5d8FDDaAEC41F13FaB46E98c; // In registry genesis-system-configs
    address constant p2pSequencerAddress = 0x57CACBB0d30b01eb2462e5dC940c161aff3230D3; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address constant batchInboxAddress = 0xff00000000000000000000000000000011155420; // In registry yaml.

    // The deployer address which is a signer on the Security Council but not Foundation safe (on Sepolia).
    address constant deployerAddress = 0x78339d822c23D943E4a2d4c3DD5408F66e6D662D;

    // Hardcoded data that should not change after execution.
    uint256 l2GenesisBlockGasLimit = 30e6;
    uint256 xdmSenderSlotNumber = 204; // Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L93-L99

    // Data that should not change after execution, fetching during `setUp`.
    uint256 gasPriceOracleOverhead;
    uint256 gasPriceOracleScalar;
    address superchainConfigGuardian;
    uint256 l2BlockTime;
    uint256 l2OutputOracleSubmissionInterval;
    uint256 finalizationPeriodSeconds;
    uint256 l2OutputOracleStartingTimestamp;
    uint256 l2OutputOracleStartingBlockNumber;
    address protocolVersionsOwner;
    uint256 requiredProtocolVersion;
    uint256 recommendedProtocolVersion;

    // Other data we use.
    uint256 systemConfigStartBlock = 4071248;
    AddressManager addressManager = AddressManager(0x9bFE9c5609311DF1c011c47642253B78a4f33F4B);
    Types.ContractSet proxies;

    // This gives the initial fork, so we can use it to switch back after fetching data.
    uint256 initialFork;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();

        // Fetch variables that are not expected to change from an older block.
        initialFork = vm.activeFork();
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), block.number - 10);

        gasPriceOracleOverhead = IFetcher(proxies.SystemConfig).overhead();
        gasPriceOracleScalar = IFetcher(proxies.SystemConfig).scalar();
        superchainConfigGuardian = IFetcher(proxies.SuperchainConfig).guardian();
        l2BlockTime = IFetcher(proxies.L2OutputOracle).L2_BLOCK_TIME();
        l2OutputOracleSubmissionInterval = IFetcher(proxies.L2OutputOracle).SUBMISSION_INTERVAL();
        finalizationPeriodSeconds = IFetcher(proxies.L2OutputOracle).FINALIZATION_PERIOD_SECONDS();
        l2OutputOracleStartingTimestamp = IFetcher(proxies.L2OutputOracle).startingTimestamp();
        l2OutputOracleStartingBlockNumber = IFetcher(proxies.L2OutputOracle).startingBlockNumber();
        protocolVersionsOwner = IFetcher(proxies.ProtocolVersions).owner();
        requiredProtocolVersion = IFetcher(proxies.ProtocolVersions).required();
        recommendedProtocolVersion = IFetcher(proxies.ProtocolVersions).recommended();

        vm.selectFork(initialFork);
    }

    function checkSemvers() internal view {
        // These are the expected semvers based on the `op-contracts/v1.4.0-rc.4` release.
        // https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.4.0-rc.4
        require(ISemver(proxies.L1CrossDomainMessenger).version().eq("2.3.0"), "semver-100");
        require(ISemver(proxies.L1StandardBridge).version().eq("2.1.0"), "semver-200");
        require(ISemver(proxies.L2OutputOracle).version().eq("1.8.0"), "semver-300");
        require(ISemver(proxies.OptimismMintableERC20Factory).version().eq("1.9.0"), "semver-400");
        require(ISemver(proxies.OptimismPortal).version().eq("3.10.0"), "semver-500");
        require(ISemver(proxies.SystemConfig).version().eq("2.2.0"), "semver-600");
        require(ISemver(proxies.L1ERC721Bridge).version().eq("2.1.0"), "semver-700");
        require(ISemver(proxies.ProtocolVersions).version().eq("1.0.0"), "semver-800");
        require(ISemver(proxies.SuperchainConfig).version().eq("1.1.0"), "semver-900");
    }

    /// @notice Asserts that the SystemConfig is setup correctly
    function checkSystemConfig() internal view {
        console.log("Running assertions on the SystemConfig");

        require(proxies.SystemConfig.code.length != 0, "200");
        require(EIP1967Helper.getImplementation(proxies.SystemConfig).code.length != 0, "201");

        SystemConfig systemConfig = SystemConfig(proxies.SystemConfig);
        ResourceMetering.ResourceConfig memory resourceConfigToCheck = systemConfig.resourceConfig();

        require(systemConfig.owner() == systemConfigOwner, "300");
        require(systemConfig.overhead() == gasPriceOracleOverhead, "400");
        require(systemConfig.scalar() == gasPriceOracleScalar, "500");
        require(systemConfig.batcherHash() == bytes32(uint256(uint160(batchSenderAddress))), "600");
        require(systemConfig.gasLimit() == uint64(l2GenesisBlockGasLimit), "700");
        require(systemConfig.unsafeBlockSigner() == p2pSequencerAddress, "800");

        // Check _config
        require(
            keccak256(abi.encode(resourceConfigToCheck)) == keccak256(abi.encode(Constants.DEFAULT_RESOURCE_CONFIG())),
            "900"
        );

        require(systemConfig.startBlock() == systemConfigStartBlock, "1500");
        require(systemConfig.batchInbox() == batchInboxAddress, "1600");

        // Check _addresses
        require(systemConfig.l1CrossDomainMessenger() == proxies.L1CrossDomainMessenger, "1700");
        require(systemConfig.l1CrossDomainMessenger().code.length != 0, "1740");

        // L1CrossDomainMessenger is a ResolvedDelegateProxy and that has no getters, so we hardcode some info needed here.
        address l1xdmImplementation = addressManager.getAddress("OVM_L1CrossDomainMessenger");
        require(l1xdmImplementation.code.length != 0, "1750");

        require(systemConfig.l1ERC721Bridge() == proxies.L1ERC721Bridge, "1800");
        require(systemConfig.l1ERC721Bridge().code.length != 0, "1801");
        require(EIP1967Helper.getImplementation(systemConfig.l1ERC721Bridge()).code.length != 0, "1802");

        require(systemConfig.l1StandardBridge() == proxies.L1StandardBridge, "1900");
        require(systemConfig.l1StandardBridge().code.length != 0, "1901");
        require(EIP1967Helper.getImplementation(systemConfig.l1StandardBridge()).code.length != 0, "1902");

        // require(systemConfig.l2OutputOracle() == proxies.L2OutputOracle, "2000");
        // require(systemConfig.l2OutputOracle().code.length != 0, "2001");
        // require(EIP1967Helper.getImplementation(systemConfig.l2OutputOracle()).code.length != 0, "2002");

        require(systemConfig.optimismPortal() == proxies.OptimismPortal, "2100");
        require(systemConfig.optimismPortal().code.length != 0, "2101");
        require(EIP1967Helper.getImplementation(systemConfig.optimismPortal()).code.length != 0, "2102");

        require(systemConfig.optimismMintableERC20Factory() == proxies.OptimismMintableERC20Factory, "2200");
        require(systemConfig.optimismMintableERC20Factory().code.length != 0, "2201");
        require(EIP1967Helper.getImplementation(systemConfig.optimismMintableERC20Factory()).code.length != 0, "2202");
    }

    /// @notice Asserts that the L1CrossDomainMessenger is setup correctly
    function checkL1CrossDomainMessenger() internal view {
        console.log("Running assertions on the L1CrossDomainMessenger");

        require(proxies.L1CrossDomainMessenger.code.length != 0, "2300");

        L1CrossDomainMessenger messengerToCheck = L1CrossDomainMessenger(proxies.L1CrossDomainMessenger);

        require(address(messengerToCheck.OTHER_MESSENGER()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER, "2400");
        require(address(messengerToCheck.otherMessenger()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER, "2500");

        require(address(messengerToCheck.PORTAL()) == proxies.OptimismPortal, "2600");
        require(address(messengerToCheck.portal()) == proxies.OptimismPortal, "2700");
        require(address(messengerToCheck.portal()).code.length != 0, "2701");
        require(EIP1967Helper.getImplementation(address(messengerToCheck.portal())).code.length != 0, "2702");

        require(address(messengerToCheck.superchainConfig()) == proxies.SuperchainConfig, "2800");
        require(address(messengerToCheck.superchainConfig()).code.length != 0, "2801");
        require(EIP1967Helper.getImplementation(address(messengerToCheck.superchainConfig())).code.length != 0, "2802");

        bytes32 xdmSenderSlot = vm.load(address(messengerToCheck), bytes32(xdmSenderSlotNumber));
        require(address(uint160(uint256(xdmSenderSlot))) == Constants.DEFAULT_L2_SENDER, "2900");
    }

    /// @notice Asserts that the L1StandardBridge is setup correctly
    function checkL1StandardBridge() internal view {
        console.log("Running assertions on the L1StandardBridge");

        require(proxies.L1StandardBridge.code.length != 0, "2901");
        require(EIP1967Helper.getImplementation(proxies.L1StandardBridge).code.length != 0, "2901");

        L1StandardBridge bridgeToCheck = L1StandardBridge(payable(proxies.L1StandardBridge));

        require(address(bridgeToCheck.MESSENGER()) == proxies.L1CrossDomainMessenger, "3000");
        require(address(bridgeToCheck.messenger()) == proxies.L1CrossDomainMessenger, "3100");
        require(address(bridgeToCheck.messenger()).code.length != 0, "3101");
        // This messenger is the L1CrossDomainMessenger and we've already checked it's implementation for code above.

        require(address(bridgeToCheck.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE, "3200");
        require(address(bridgeToCheck.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE, "3300");

        require(address(bridgeToCheck.superchainConfig()) == proxies.SuperchainConfig, "3400");
        require(address(bridgeToCheck.superchainConfig()).code.length != 0, "3401");
        require(EIP1967Helper.getImplementation(address(bridgeToCheck.superchainConfig())).code.length != 0, "3402");
    }

    /// @notice Asserts that the L2OutputOracle is setup correctly
    function checkL2OutputOracle() internal view {
        console.log("Running assertions on the L2OutputOracle");

        require(proxies.L2OutputOracle.code.length != 0, "3500");

        require(EIP1967Helper.getImplementation(proxies.L2OutputOracle).code.length != 0, "3501");

        L2OutputOracle oracleToCheck = L2OutputOracle(proxies.L2OutputOracle);

        require(oracleToCheck.SUBMISSION_INTERVAL() == l2OutputOracleSubmissionInterval, "3600");
        require(oracleToCheck.submissionInterval() == l2OutputOracleSubmissionInterval, "3700");

        require(oracleToCheck.L2_BLOCK_TIME() == l2BlockTime, "3800");
        require(oracleToCheck.l2BlockTime() == l2BlockTime, "3900");

        require(oracleToCheck.PROPOSER() == l2OutputOracleProposer, "4000");
        require(oracleToCheck.proposer() == l2OutputOracleProposer, "4100");

        require(oracleToCheck.CHALLENGER() == l2OutputOracleChallenger, "4200");
        require(oracleToCheck.challenger() == l2OutputOracleChallenger, "4300");

        require(oracleToCheck.FINALIZATION_PERIOD_SECONDS() == finalizationPeriodSeconds, "4400");
        require(oracleToCheck.finalizationPeriodSeconds() == finalizationPeriodSeconds, "4500");

        require(oracleToCheck.startingBlockNumber() == l2OutputOracleStartingBlockNumber, "4600");
        require(oracleToCheck.startingTimestamp() == l2OutputOracleStartingTimestamp, "4700");
    }

    /// @notice Asserts that the OptimismMintableERC20Factory is setup correctly
    function checkOptimismMintableERC20Factory() internal view {
        console.log("Running assertions on the OptimismMintableERC20Factory");

        require(proxies.OptimismMintableERC20Factory.code.length != 0, "4800");

        require(EIP1967Helper.getImplementation(proxies.OptimismMintableERC20Factory).code.length != 0, "4801");

        OptimismMintableERC20Factory factoryToCheck = OptimismMintableERC20Factory(proxies.OptimismMintableERC20Factory);

        require(factoryToCheck.BRIDGE() == proxies.L1StandardBridge, "4900");
        require(factoryToCheck.bridge() == proxies.L1StandardBridge, "5000");
        require(factoryToCheck.bridge().code.length != 0, "5001");
        require(EIP1967Helper.getImplementation(factoryToCheck.bridge()).code.length != 0, "5002");
    }

    /// @notice Asserts that the L1ERC721Bridge is setup correctly
    function checkL1ERC721Bridge() internal view {
        console.log("Running assertions on the L1ERC721Bridge");

        require(proxies.L1ERC721Bridge.code.length != 0, "5100");

        require(EIP1967Helper.getImplementation(proxies.L1ERC721Bridge).code.length != 0, "5101");

        L1ERC721Bridge bridgeToCheck = L1ERC721Bridge(proxies.L1ERC721Bridge);

        require(address(bridgeToCheck.OTHER_BRIDGE()) == Predeploys.L2_ERC721_BRIDGE, "5200");
        require(address(bridgeToCheck.otherBridge()) == Predeploys.L2_ERC721_BRIDGE, "5300");

        require(address(bridgeToCheck.MESSENGER()) == proxies.L1CrossDomainMessenger, "5400");
        require(address(bridgeToCheck.messenger()) == proxies.L1CrossDomainMessenger, "5500");
        require(address(bridgeToCheck.messenger()).code.length != 0, "5502");

        require(address(bridgeToCheck.superchainConfig()) == proxies.SuperchainConfig, "5600");
        require(address(bridgeToCheck.superchainConfig()).code.length != 0, "5601");
        require(EIP1967Helper.getImplementation(address(bridgeToCheck.superchainConfig())).code.length != 0, "5603");
    }

    /// @notice Asserts the OptimismPortal is setup correctly
    function checkOptimismPortal() internal view {
        console.log("Running assertions on the OptimismPortal");

        require(proxies.OptimismPortal.code.length != 0, "5700");

        require(EIP1967Helper.getImplementation(proxies.OptimismPortal).code.length != 0, "5701");

        OptimismPortal portalToCheck = OptimismPortal(payable(proxies.OptimismPortal));

        require(address(portalToCheck.systemConfig()) == proxies.SystemConfig, "6000");
        require(address(portalToCheck.systemConfig()) == proxies.SystemConfig, "6100");
        require(address(portalToCheck.systemConfig()).code.length != 0, "6101");
        require(EIP1967Helper.getImplementation(address(portalToCheck.systemConfig())).code.length != 0, "6102");

        require(portalToCheck.guardian() == superchainConfigGuardian, "6200");
        require(portalToCheck.guardian() == superchainConfigGuardian, "6300");
        require(portalToCheck.guardian().code.length != 0, "6350"); // This is a Safe, no need to check the implementation.

        require(address(portalToCheck.superchainConfig()) == address(proxies.SuperchainConfig), "6400");
        require(address(portalToCheck.superchainConfig()).code.length != 0, "6401");
        require(EIP1967Helper.getImplementation(address(portalToCheck.superchainConfig())).code.length != 0, "6402");

        require(portalToCheck.paused() == SuperchainConfig(proxies.SuperchainConfig).paused(), "6500");

        require(portalToCheck.l2Sender() == Constants.DEFAULT_L2_SENDER, "6600");
    }

    /// @notice Asserts that the ProtocolVersions is setup correctly
    function checkProtocolVersions() internal view {
        console.log("Running assertions on the ProtocolVersions");

        require(proxies.ProtocolVersions.code.length != 0, "6700");
        require(EIP1967Helper.getImplementation(proxies.ProtocolVersions).code.length != 0, "6701");

        ProtocolVersions protocolVersionsToCheck = ProtocolVersions(proxies.ProtocolVersions);
        require(protocolVersionsToCheck.owner() == protocolVersionsOwner, "6800");
        require(ProtocolVersion.unwrap(protocolVersionsToCheck.required()) == requiredProtocolVersion, "6900");
        require(ProtocolVersion.unwrap(protocolVersionsToCheck.recommended()) == recommendedProtocolVersion, "7000");
    }

    /// @notice Asserts that the SuperchainConfig is setup correctly
    function checkSuperchainConfig() internal view {
        console.log("Running assertions on the SuperchainConfig");

        require(proxies.SuperchainConfig.code.length != 0, "7100");
        require(EIP1967Helper.getImplementation(proxies.SuperchainConfig).code.length != 0, "7101");

        SuperchainConfig superchainConfigToCheck = SuperchainConfig(proxies.SuperchainConfig);
        require(superchainConfigToCheck.guardian() == superchainConfigGuardian, "7200");
        require(superchainConfigToCheck.guardian().code.length != 0, "7250");
        require(superchainConfigToCheck.paused() == false, "7300");
    }

    function checkLivenessModule() internal view {
        console.log("Running assertions on the LivenessModule");

        require(livenessModule.version().eq("1.2.0"), "checkLivenessModule-000");
        require(livenessModule.safe() == address(securityCouncilSafe), "checkLivenessModule-100");
        require(livenessModule.livenessGuard() == address(livenessGuard), "checkLivenessModule-200");
        require(livenessModule.livenessInterval() == 62899200, "checkLivenessModule-300");
        require(livenessModule.minOwners() == 2, "checkLivenessModule-400");
        require(livenessModule.thresholdPercentage() == 30, "checkLivenessModule-500");
        require(livenessModule.fallbackOwner() == address(foundationUpgradesSafe), "checkLivenessModule-600");
    }

    function checkLivenessGuard() internal view {
        console.log("Running assertions on the LivenessGuard");

        require(livenessGuard.version().eq("1.0.0"), "checkLivenessGuard-000");
        require(livenessGuard.safe() == address(securityCouncilSafe), "checkLivenessGuard-100");
    }

    function checkDeputyGuardianModule() internal view {
        console.log("Running assertions on the DeputyGuardianModule");

        require(deputyGuardianModule.version().eq("1.1.0"), "checkDeputyGuardianModule-000");
        require(
            deputyGuardianModule.deputyGuardian() == address(foundationOperationsSafe), "checkDeputyGuardianModule-100"
        );
        require(deputyGuardianModule.safe() == address(guardianSafe), "checkDeputyGuardianModule-200");
        require(
            deputyGuardianModule.superchainConfig() == address(proxies.SuperchainConfig),
            "checkDeputyGuardianModule-300"
        );
    }

    function checkSecurityCouncilSafe() internal view {
        console.log("Running assertions on the SecurityCouncilSafe");

        // The SecurityCouncilSafe and FoundationSafe should have the same set of owners on Sepolia only,
        // with the exception of the extra deployer address which is still included to facilitate testing.
        address[] memory councilOwners = securityCouncilSafe.getOwners();
        address[] memory foundationOwners = foundationUpgradesSafe.getOwners();
        require(councilOwners.length == foundationOwners.length + 1, "checkSecurityCouncilSafe-200");
        for (uint256 i = 0; i < councilOwners.length; i++) {
            if (councilOwners[i] != deployerAddress) {
                require(foundationUpgradesSafe.isOwner(councilOwners[i]), "checkSecurityCouncilSafe-201");
            }
        }

        // See sepolia.json for config values being verified:
        // https://github.com/ethereum-optimism/optimism/pull/10224/files
        require(securityCouncilSafe.getThreshold() == 3, "checkSecurityCouncilSafe-301");
    }

    function checkOwnershipConfiguration() internal {
        (address[] memory modules, address nextModule) =
            ModuleManager(guardianSafe).getModulesPaginated(SENTINEL_MODULE, 1);
        deputyGuardianModule = IDeputyGuardianModuleFetcher(modules[0]);
        require(modules.length == 1, "checkOwnershipConfiguration-50");
        require(address(deputyGuardianModule) == expectedDeputyGuardianModule, "checkOwnershipConfiguration-100");
        require(nextModule == SENTINEL_MODULE, "checkOwnershipConfiguration-125");

        (modules, nextModule) = ModuleManager(securityCouncilSafe).getModulesPaginated(SENTINEL_MODULE, 1);
        livenessModule = ILivenessModuleFetcher(modules[0]);
        require(modules.length == 1, "checkOwnershipConfiguration-150");
        require(address(livenessModule) == expectedLivenessModule, "checkOwnershipConfiguration-200");
        require(nextModule == SENTINEL_MODULE, "checkOwnershipConfiguration-225");

        bytes32 _livenessGuard = vm.load(address(securityCouncilSafe), GUARD_STORAGE_SLOT);
        livenessGuard = ILivenessGuardFetcher(address(uint160(uint256(_livenessGuard))));
        require(address(livenessGuard) == expectedLivenessGuard, "checkOwnershipConfiguration-300");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkSemvers();
        checkOwnershipConfiguration();

        checkSystemConfig();
        checkL1CrossDomainMessenger();
        checkL1StandardBridge();
        // checkL2OutputOracle();
        checkOptimismMintableERC20Factory();
        checkL1ERC721Bridge();
        checkOptimismPortal();
        checkProtocolVersions();
        checkSuperchainConfig();
        checkSecurityCouncilSafe();
        checkLivenessModule();
        checkLivenessGuard();
        checkDeputyGuardianModule();

        console.log("All assertions passed!");
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Safe owners will appear in storage in the LivenessGuard when added
        address[] memory securityCouncilSafeOwners = securityCouncilSafe.getOwners();
        address[] memory shouldHaveCodeExceptions = new address[](6 + securityCouncilSafeOwners.length);

        shouldHaveCodeExceptions[0] = l2OutputOracleProposer;
        shouldHaveCodeExceptions[1] = l2OutputOracleChallenger;
        shouldHaveCodeExceptions[2] = systemConfigOwner;
        shouldHaveCodeExceptions[3] = batchSenderAddress;
        shouldHaveCodeExceptions[4] = p2pSequencerAddress;
        shouldHaveCodeExceptions[5] = batchInboxAddress;

        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            shouldHaveCodeExceptions[6 + i] = securityCouncilSafeOwners[i];
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
        _proxies.L2OutputOracle = stdJson.readAddress(addressesJson, "$.L2OutputOracleProxy");
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
