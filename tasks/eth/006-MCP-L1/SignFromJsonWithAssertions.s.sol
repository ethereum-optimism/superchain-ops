// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson} from "./SignFromJson.s.sol";
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
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract PostCheck is SignFromJson {
    /// @dev Verify that the slot number of xDomainMsgSender in lib/optimism/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json
    ///      is 24. If not, update xdmSenderSlotNumber to the correct slot number.
    uint256 constant xdmSenderSlotNumber = 24;

    DeployConfig constant cfg = DeployConfig(address(uint160(uint256(keccak256(abi.encode("optimism.deployconfig"))))));

    Types.ContractSet prox;

    uint256 l2OutputOracleStartingTimestamp;

    constructor() {
        prox = _getContractSet();

        vm.etch(address(cfg), vm.getDeployedCode("DeployConfig.s.sol:DeployConfig"));
        vm.label(address(cfg), "DeployConfig");
        vm.allowCheatcodes(address(cfg));
        cfg.read(vm.envOr("DEPLOY_CONFIG_PATH", string.concat(vm.projectRoot(), "/deploy-config/mainnet.json")));

        l2OutputOracleStartingTimestamp = cfg.l2OutputOracleStartingTimestamp();
    }

    function _postCheck() internal view override {
        postDeployAssertions();
    }

    /// @notice Asserts the correctness of an L1 deployment. This function expects that all contracts
    ///         within the `prox` ContractSet are proxies that have been setup and initialized.
    function postDeployAssertions() internal view {
        console.log("Running post-deploy assertions");
        ResourceMetering.ResourceConfig memory rcfg = SystemConfig(prox.SystemConfig).resourceConfig();
        ResourceMetering.ResourceConfig memory dflt = Constants.DEFAULT_RESOURCE_CONFIG();
        require(keccak256(abi.encode(rcfg)) == keccak256(abi.encode(dflt)), "100");

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

    /// @notice Asserts that the SystemConfig is setup correctly
    function checkSystemConfig() internal view {
        console.log("Running chain assertions on the SystemConfig");
        SystemConfig config = SystemConfig(prox.SystemConfig);

        require(config.code.length != 0, "200");

        ResourceMetering.ResourceConfig memory resourceConfig = config.resourceConfig();

        require(config.owner() == cfg.finalSystemOwner(), "300");
        require(config.overhead() == cfg.gasPriceOracleOverhead(), "400");
        require(config.scalar() == cfg.gasPriceOracleScalar(), "500");
        require(config.batcherHash() == bytes32(uint256(uint160(cfg.batchSenderAddress()))), "600");
        require(config.gasLimit() == uint64(cfg.l2GenesisBlockGasLimit()), "700");
        require(config.unsafeBlockSigner() == cfg.p2pSequencerAddress(), "800");
        // Check _config
        ResourceMetering.ResourceConfig memory rconfig = Constants.DEFAULT_RESOURCE_CONFIG();

        require(resourceConfig.maxResourceLimit == rconfig.maxResourceLimit, "900");
        require(resourceConfig.elasticityMultiplier == rconfig.elasticityMultiplier, "1000");
        require(resourceConfig.baseFeeMaxChangeDenominator == rconfig.baseFeeMaxChangeDenominator, "1100");
        require(resourceConfig.systemTxMaxGas == rconfig.systemTxMaxGas, "1200");
        require(resourceConfig.minimumBaseFee == rconfig.minimumBaseFee, "1300");
        require(resourceConfig.maximumBaseFee == rconfig.maximumBaseFee, "1400");
        // Depends on start block being set to 0 in `initialize`
        uint256 cfgStartBlock = cfg.systemConfigStartBlock();
        require(config.startBlock() == (cfgStartBlock == 0 ? block.number : cfgStartBlock), "1500");
        require(config.batchInbox() == cfg.batchInboxAddress(), "1600");
        // Check _addresses
        require(config.l1CrossDomainMessenger() == prox.L1CrossDomainMessenger, "1700");
        require(config.l1ERC721Bridge() == prox.L1ERC721Bridge, "1800");
        require(config.l1StandardBridge() == prox.L1StandardBridge, "1900");
        require(config.l2OutputOracle() == prox.L2OutputOracle, "2000");
        require(config.optimismPortal() == prox.OptimismPortal, "2100");
        require(config.optimismMintableERC20Factory() == prox.OptimismMintableERC20Factory, "2200");
    }

    /// @notice Asserts that the L1CrossDomainMessenger is setup correctly
    function checkL1CrossDomainMessenger() internal view {
        console.log("Running chain assertions on the L1CrossDomainMessenger");
        L1CrossDomainMessenger messenger = L1CrossDomainMessenger(prox.L1CrossDomainMessenger);

        require(messenger.code.length != 0, "2300");

        require(address(messenger.OTHER_MESSENGER()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER, "2400");
        require(address(messenger.otherMessenger()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER, "2500");

        require(address(messenger.PORTAL()) == prox.OptimismPortal, "2600");
        require(address(messenger.portal()) == prox.OptimismPortal, "2700");
        require(address(messenger.superchainConfig()) == prox.SuperchainConfig, "2800");
        bytes32 xdmSenderSlot = vm.load(address(messenger), bytes32(xdmSenderSlotNumber));
        require(address(uint160(uint256(xdmSenderSlot))) == Constants.DEFAULT_L2_SENDER, "2900");
    }

    /// @notice Asserts that the L1StandardBridge is setup correctly
    function checkL1StandardBridge() internal view {
        console.log("Running chain assertions on the L1StandardBridge");
        L1StandardBridge bridge = L1StandardBridge(payable(prox.L1StandardBridge));

        require(address(bridge.MESSENGER()) == prox.L1CrossDomainMessenger, "3000");
        require(address(bridge.messenger()) == prox.L1CrossDomainMessenger, "3100");
        require(address(bridge.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE, "3200");
        require(address(bridge.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE, "3300");
        require(address(bridge.superchainConfig()) == prox.SuperchainConfig, "3400");
    }

    /// @notice Asserts that the L2OutputOracle is setup correctly
    function checkL2OutputOracle() internal view {
        console.log("Running chain assertions on the L2OutputOracle");
        L2OutputOracle oracle = L2OutputOracle(prox.L2OutputOracle);

        require(oracle.code.length != 0, "3500");

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
        OptimismMintableERC20Factory factory = OptimismMintableERC20Factory(prox.OptimismMintableERC20Factory);

        require(factory.code.length != 0, "4800");

        require(factory.BRIDGE() == prox.L1StandardBridge, "4900");
        require(factory.bridge() == prox.L1StandardBridge, "5000");
    }

    /// @notice Asserts that the L1ERC721Bridge is setup correctly
    function checkL1ERC721Bridge() internal view {
        console.log("Running chain assertions on the L1ERC721Bridge");
        L1ERC721Bridge bridge = L1ERC721Bridge(prox.L1ERC721Bridge);

        require(bridge.code.length != 0, "5100");

        require(address(bridge.OTHER_BRIDGE()) == Predeploys.L2_ERC721_BRIDGE, "5200");
        require(address(bridge.otherBridge()) == Predeploys.L2_ERC721_BRIDGE, "5300");

        require(address(bridge.MESSENGER()) == prox.L1CrossDomainMessenger, "5400");
        require(address(bridge.messenger()) == prox.L1CrossDomainMessenger, "5500");
        require(address(bridge.superchainConfig()) == prox.SuperchainConfig, "5600");
    }

    /// @notice Asserts the OptimismPortal is setup correctly
    function checkOptimismPortal() internal view {
        console.log("Running chain assertions on the OptimismPortal");

        OptimismPortal portal = OptimismPortal(payable(prox.OptimismPortal));

        require(portal.code.length != 0, "5700");

        address guardian = cfg.superchainConfigGuardian();

        require(address(portal.L2_ORACLE()) == prox.L2OutputOracle, "5800");
        require(address(portal.l2Oracle()) == prox.L2OutputOracle, "5900");
        require(address(portal.SYSTEM_CONFIG()) == prox.SystemConfig, "6000");
        require(address(portal.systemConfig()) == prox.SystemConfig, "6100");
        require(portal.GUARDIAN() == guardian, "6200");
        require(portal.guardian() == guardian, "6300");
        require(address(portal.superchainConfig()) == address(prox.SuperchainConfig), "6400");
        require(portal.paused() == SuperchainConfig(prox.SuperchainConfig).paused(), "6500");
        require(portal.l2Sender() == Constants.DEFAULT_L2_SENDER, "6600");
    }

    /// @notice Asserts that the ProtocolVersions is setup correctly
    function checkProtocolVersions() internal view {
        console.log("Running chain assertions on the ProtocolVersions");
        ProtocolVersions versions = ProtocolVersions(prox.ProtocolVersions);

        require(versions.code.length != 0, "6700");

        require(versions.owner() == cfg.finalSystemOwner(), "6800");
        require(ProtocolVersion.unwrap(versions.required()) == cfg.requiredProtocolVersion(), "6900");
        require(ProtocolVersion.unwrap(versions.recommended()) == cfg.recommendedProtocolVersion(), "7000");
    }

    /// @notice Asserts that the SuperchainConfig is setup correctly
    function checkSuperchainConfig() internal view {
        console.log("Running chain assertions on the SuperchainConfig");
        SuperchainConfig superchainConfig = SuperchainConfig(prox.SuperchainConfig);

        require(superchainConfig.code.length != 0, "7100");

        require(superchainConfig.guardian() == cfg.superchainConfigGuardian(), "7200");
        require(superchainConfig.paused() == false, "7300");
    }

    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory _json;

        // Read extra addresses
        try vm.readFile(
            string.concat(vm.projectRoot(), "/lib/superchain-registry/superchain/extra/addresses/mainnet/op.json")
        ) returns (string memory data) {
            _json = data;
        } catch {
            revert("Failed to read extra addresses file for mainnet.");
        }

        _proxies.L1CrossDomainMessenger = stdJson.readAddress(_json, "$.L1CrossDomainMessengerProxy");
        _proxies.L1StandardBridge = stdJson.readAddress(_json, "$.L1StandardBridgeProxy");
        _proxies.L2OutputOracle = stdJson.readAddress(_json, "$.L2OutputOracleProxy");
        _proxies.OptimismMintableERC20Factory = stdJson.readAddress(_json, "$.OptimismMintableERC20FactoryProxy");
        _proxies.OptimismPortal = stdJson.readAddress(_json, "$.OptimismPortalProxy");
        _proxies.OptimismPortal2 = stdJson.readAddress(_json, "$.OptimismPortalProxy");
        _proxies.SystemConfig = stdJson.readAddress(_json, "$.SystemConfigProxy");
        _proxies.L1ERC721Bridge = stdJson.readAddress(_json, "$.L1ERC721BridgeProxy");

        _proxies.ProtocolVersions = stdJson.readAddress(_json, "$.finalSystemOwner");
        _proxies.SuperchainConfig = stdJson.readAddress(_json, "$.finalSystemOwner");

        return _proxies;
    }
}
