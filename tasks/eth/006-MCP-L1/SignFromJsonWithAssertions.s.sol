// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson} from "../../../script/SignFromJson.s.sol";
import {DeployConfig} from "@eth-optimism-bedrock/scripts/DeployConfig.s.sol";
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
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {Deployer} from "@eth-optimism-bedrock/scripts/Deployer.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract SignFromJsonWithAssertions is SignFromJson, Deployer {
    Types.ContractSet proxies;

    uint256 l2OutputOracleStartingTimestamp;

    uint256 xdmSenderSlotNumber;

    /// @notice Sets up the contract.
    function setUp() public override {
        super.setUp();

        proxies = _getContractSet();

        l2OutputOracleStartingTimestamp = cfg.l2OutputOracleStartingTimestamp();

        // Read the slot number for the xDomainMsgSender in the L1CrossDomainMessenger
        try vm.readFile(
            string.concat(
                vm.projectRoot(),
                "/lib/optimism/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json"
            )
        ) returns (string memory data) {
            xdmSenderSlotNumber = stdJson.readUint(data, string(abi.encodePacked("$.[13].slot")));
        } catch {
            revert(
                "Failed to read xDomainMsgSender slot number in lib/optimism/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json"
            );
        }
    }

    /// @notice The name of the script
    function name() public pure override returns (string memory) {
        return "SignFromJsonWithAssertions";
    }

    /// @notice Asserts that the SystemConfig is setup correctly
    function checkSystemConfig() internal view {
        console.log("Running chain assertions on the SystemConfig");

        require(proxies.SystemConfig.code.length != 0, "200");

        SystemConfig config = SystemConfig(proxies.SystemConfig);

        ResourceMetering.ResourceConfig memory resourceConfig = config.resourceConfig();

        require(config.owner() == cfg.finalSystemOwner(), "300");
        require(config.overhead() == cfg.gasPriceOracleOverhead(), "400");
        require(config.scalar() == cfg.gasPriceOracleScalar(), "500");
        require(config.batcherHash() == bytes32(uint256(uint160(cfg.batchSenderAddress()))), "600");
        require(config.gasLimit() == uint64(cfg.l2GenesisBlockGasLimit()), "700");
        require(config.unsafeBlockSigner() == cfg.p2pSequencerAddress(), "800");
        // Check _config
        require(
            keccak256(abi.encode(resourceConfig)) == keccak256(abi.encode(Constants.DEFAULT_RESOURCE_CONFIG())), "900"
        );
        require(config.startBlock() == cfg.systemConfigStartBlock(), "1500");
        require(config.batchInbox() == cfg.batchInboxAddress(), "1600");
        // Check _addresses
        require(config.l1CrossDomainMessenger() == proxies.L1CrossDomainMessenger, "1700");
        require(config.l1CrossDomainMessenger().code.length != 0, "1701");
        require(config.l1ERC721Bridge() == proxies.L1ERC721Bridge, "1800");
        require(config.l1ERC721Bridge().code.length != 0, "1801");
        require(config.l1StandardBridge() == proxies.L1StandardBridge, "1900");
        require(config.l1StandardBridge().code.length != 0, "1901");
        require(config.l2OutputOracle() == proxies.L2OutputOracle, "2000");
        require(config.l2OutputOracle().code.length != 0, "2001");
        require(config.optimismPortal() == proxies.OptimismPortal, "2100");
        require(config.optimismPortal().code.length != 0, "2101");
        require(config.optimismMintableERC20Factory() == proxies.OptimismMintableERC20Factory, "2200");
        require(config.optimismMintableERC20Factory().code.length != 0, "2201");
    }

    /// @notice Asserts that the L1CrossDomainMessenger is setup correctly
    function checkL1CrossDomainMessenger() internal view {
        console.log("Running chain assertions on the L1CrossDomainMessenger");

        require(proxies.L1CrossDomainMessenger.code.length != 0, "2300");

        L1CrossDomainMessenger messenger = L1CrossDomainMessenger(proxies.L1CrossDomainMessenger);

        require(address(messenger.OTHER_MESSENGER()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER, "2400");
        require(address(messenger.otherMessenger()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER, "2500");
        require(address(messenger.otherMessenger()).code.length != 0, "2501");

        require(address(messenger.PORTAL()) == proxies.OptimismPortal, "2600");
        require(address(messenger.portal()) == proxies.OptimismPortal, "2700");
        require(address(messenger.portal()).code.length != 0, "2701");

        require(address(messenger.superchainConfig()) == proxies.SuperchainConfig, "2800");
        require(address(messenger.superchainConfig()).code.length != 0, "2801");

        bytes32 xdmSenderSlot = vm.load(address(messenger), bytes32(xdmSenderSlotNumber));
        require(address(uint160(uint256(xdmSenderSlot))) == Constants.DEFAULT_L2_SENDER, "2900");
    }

    /// @notice Asserts that the L1StandardBridge is setup correctly
    function checkL1StandardBridge() internal view {
        console.log("Running chain assertions on the L1StandardBridge");
        L1StandardBridge bridge = L1StandardBridge(payable(proxies.L1StandardBridge));

        require(address(bridge.MESSENGER()) == proxies.L1CrossDomainMessenger, "3000");
        require(address(bridge.messenger()) == proxies.L1CrossDomainMessenger, "3100");
        require(address(bridge.messenger()).code.length != 0, "3101");

        require(address(bridge.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE, "3200");
        require(address(bridge.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE, "3300");
        require(address(bridge.otherBridge()).code.length != 0, "3302");

        require(address(bridge.superchainConfig()) == proxies.SuperchainConfig, "3400");
        require(address(bridge.superchainConfig()).code.length != 0, "3303");
    }

    /// @notice Asserts that the L2OutputOracle is setup correctly
    function checkL2OutputOracle() internal view {
        console.log("Running chain assertions on the L2OutputOracle");

        require(proxies.L2OutputOracle.code.length != 0, "3500");

        L2OutputOracle oracle = L2OutputOracle(proxies.L2OutputOracle);

        require(oracle.SUBMISSION_INTERVAL() == cfg.l2OutputOracleSubmissionInterval(), "3600");
        require(oracle.submissionInterval() == cfg.l2OutputOracleSubmissionInterval(), "3700");
        require(oracle.L2_BLOCK_TIME() == cfg.l2BlockTime(), "3800");
        require(oracle.l2BlockTime() == cfg.l2BlockTime(), "3900");
        require(oracle.PROPOSER() == cfg.l2OutputOracleProposer(), "4000");
        require(oracle.proposer() == cfg.l2OutputOracleProposer(), "4100");
        require(oracle.CHALLENGER() == cfg.l2OutputOracleChallenger(), "4200");
        require(oracle.challenger() == cfg.l2OutputOracleChallenger(), "4300");
        require(oracle.FINALIZATION_PERIOD_SECONDS() == cfg.finalizationPeriodSeconds(), "4400");
        require(oracle.finalizationPeriodSeconds() == cfg.finalizationPeriodSeconds(), "4500");
        require(oracle.startingBlockNumber() == cfg.l2OutputOracleStartingBlockNumber(), "4600");
        require(oracle.startingTimestamp() == l2OutputOracleStartingTimestamp, "4700");
    }

    /// @notice Asserts that the OptimismMintableERC20Factory is setup correctly
    function checkOptimismMintableERC20Factory() internal view {
        console.log("Running chain assertions on the OptimismMintableERC20Factory");

        require(proxies.OptimismMintableERC20Factory.code.length != 0, "4800");

        OptimismMintableERC20Factory factory = OptimismMintableERC20Factory(proxies.OptimismMintableERC20Factory);

        require(factory.BRIDGE() == proxies.L1StandardBridge, "4900");
        require(factory.bridge() == proxies.L1StandardBridge, "5000");
        require(factory.bridge().code.length != 0, "5001");
    }

    /// @notice Asserts that the L1ERC721Bridge is setup correctly
    function checkL1ERC721Bridge() internal view {
        console.log("Running chain assertions on the L1ERC721Bridge");

        require(proxies.L1ERC721Bridge.code.length != 0, "5100");

        L1ERC721Bridge bridge = L1ERC721Bridge(proxies.L1ERC721Bridge);

        require(address(bridge.OTHER_BRIDGE()) == Predeploys.L2_ERC721_BRIDGE, "5200");
        require(address(bridge.otherBridge()) == Predeploys.L2_ERC721_BRIDGE, "5300");
        require(address(bridge.otherBridge()).code.length != 0, "5301");

        require(address(bridge.MESSENGER()) == proxies.L1CrossDomainMessenger, "5400");
        require(address(bridge.messenger()) == proxies.L1CrossDomainMessenger, "5500");
        require(address(bridge.messenger()).code.length != 0, "5502");

        require(address(bridge.superchainConfig()) == proxies.SuperchainConfig, "5600");
        require(address(bridge.superchainConfig()).code.length != 0, "5603");
    }

    /// @notice Asserts the OptimismPortal is setup correctly
    function checkOptimismPortal() internal view {
        console.log("Running chain assertions on the OptimismPortal");

        require(proxies.OptimismPortal.code.length != 0, "5700");

        OptimismPortal portal = OptimismPortal(payable(proxies.OptimismPortal));

        address guardian = cfg.superchainConfigGuardian();

        require(address(portal.L2_ORACLE()) == proxies.L2OutputOracle, "5800");
        require(address(portal.l2Oracle()) == proxies.L2OutputOracle, "5900");
        require(address(portal.l2Oracle()).code.length != 0, "5901");

        require(address(portal.SYSTEM_CONFIG()) == proxies.SystemConfig, "6000");
        require(address(portal.systemConfig()) == proxies.SystemConfig, "6100");
        require(address(portal.systemConfig()).code.length != 0, "6101");

        require(portal.GUARDIAN() == guardian, "6200");
        require(portal.guardian() == guardian, "6300");
        require(address(portal.guardian()).code.length != 0, "6301");

        require(address(portal.superchainConfig()) == address(proxies.SuperchainConfig), "6400");
        require(address(portal.superchainConfig()).code.length != 0, "6401");

        require(portal.paused() == SuperchainConfig(proxies.SuperchainConfig).paused(), "6500");
        require(portal.l2Sender() == Constants.DEFAULT_L2_SENDER, "6600");
    }

    /// @notice Asserts that the ProtocolVersions is setup correctly
    function checkProtocolVersions() internal view {
        console.log("Running chain assertions on the ProtocolVersions");

        require(proxies.ProtocolVersions.code.length != 0, "6700");

        ProtocolVersions versions = ProtocolVersions(proxies.ProtocolVersions);

        require(versions.owner() == cfg.finalSystemOwner(), "6800");

        require(ProtocolVersion.unwrap(versions.required()) == cfg.requiredProtocolVersion(), "6900");
        require(ProtocolVersion.unwrap(versions.recommended()) == cfg.recommendedProtocolVersion(), "7000");
    }

    /// @notice Asserts that the SuperchainConfig is setup correctly
    function checkSuperchainConfig() internal view {
        console.log("Running chain assertions on the SuperchainConfig");

        require(proxies.SuperchainConfig.code.length != 0, "7100");

        SuperchainConfig superchainConfig = SuperchainConfig(proxies.SuperchainConfig);

        require(superchainConfig.guardian() == cfg.superchainConfigGuardian(), "7200");
        require(superchainConfig.guardian().code.length != 0, "7201");

        require(superchainConfig.paused() == false, "7300");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck() internal view override {
        console.log("Running post-deploy assertions");

        checkSystemConfig();
        checkL1CrossDomainMessenger();
        checkL1StandardBridge();
        checkL2OutputOracle();
        checkOptimismMintableERC20Factory();
        checkL1ERC721Bridge();
        checkOptimismPortal();
        checkProtocolVersions();
        checkSuperchainConfig();
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/extra/addresses/mainnet/op.json
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory json;

        // Read op.json
        try vm.readFile(
            string.concat(vm.projectRoot(), "/lib/superchain-registry/superchain/extra/addresses/mainnet/op.json")
        ) returns (string memory data) {
            json = data;
        } catch {
            revert("Failed to read lib/superchain-registry/superchain/extra/addresses/mainnet/op.json");
        }

        _proxies.L1CrossDomainMessenger = stdJson.readAddress(json, "$.L1CrossDomainMessengerProxy");
        _proxies.L1StandardBridge = stdJson.readAddress(json, "$.L1StandardBridgeProxy");
        _proxies.L2OutputOracle = stdJson.readAddress(json, "$.L2OutputOracleProxy");
        _proxies.OptimismMintableERC20Factory = stdJson.readAddress(json, "$.OptimismMintableERC20FactoryProxy");
        _proxies.OptimismPortal = stdJson.readAddress(json, "$.OptimismPortalProxy");
        _proxies.OptimismPortal2 = stdJson.readAddress(json, "$.OptimismPortalProxy");
        _proxies.SystemConfig = stdJson.readAddress(json, "$.SystemConfigProxy");
        _proxies.L1ERC721Bridge = stdJson.readAddress(json, "$.L1ERC721BridgeProxy");

        // Get go path
        string[] memory inputs = new string[](3);
        inputs[0] = "go";
        inputs[1] = "env";
        inputs[2] = "GOPATH";
        string memory goPath = string(vm.ffi(inputs));

        // Read superchain.yaml
        inputs = new string[](4);
        inputs[0] = string.concat(goPath, "/bin/yq");
        inputs[1] = "-o";
        inputs[2] = "json";
        inputs[3] = "lib/superchain-registry/superchain/configs/mainnet/superchain.yaml";

        json = string(vm.ffi(inputs));

        _proxies.ProtocolVersions = stdJson.readAddress(json, "$.protocol_versions_addr");
        _proxies.SuperchainConfig = stdJson.readAddress(json, "$.superchain_config_addr");
    }
}
