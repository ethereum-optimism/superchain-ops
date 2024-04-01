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

contract PostCheck is SignFromJson {
    Types.ContractSet prox = Types.ContractSet({
        L1CrossDomainMessenger: 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1,
        L1StandardBridge: 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1,
        L2OutputOracle: 0xdfe97868233d1aa22e815a266982f2cf17685a27,
        DisputeGameFactory: address(0),
        OptimismMintableERC20Factory: 0x75505a97BD334E7BD3C476893285569C4136Fa0F,
        OptimismPortal: 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
        OptimismPortal2: 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
        SystemConfig: 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290,
        L1ERC721Bridge: 0x5a7749f83b81B301cAb5f48EB8516B986DAef23D,
        ProtocolVersions: 0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935,
        SuperchainConfig: 0x95703e0982140D16f8ebA6d158FccEde42f04a4C
    });
    DeployConfig public constant cfg =
        DeployConfig(address(uint160(uint256(keccak256(abi.encode("optimism.deployconfig"))))));
    uint256 l2OutputOracleStartingTimestamp = 1686068903;

    constructor() {
        vm.etch(address(cfg), vm.getDeployedCode("DeployConfig.s.sol:DeployConfig"));
        vm.label(address(cfg), "DeployConfig");
        vm.allowCheatcodes(address(cfg));
        cfg.read(vm.envOr("DEPLOY_CONFIG_PATH", string.concat(vm.projectRoot(), "/deploy-config/mainnet.json")));
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
        require(keccak256(abi.encode(rcfg)) == keccak256(abi.encode(dflt)));

        checkSystemConfig();
        checkL1CrossDomainMessenger();
        checkL1StandardBridge();
        checkL2OutputOracle();
        checkOptimismMintableERC20Factory();
        checkL1ERC721Bridge();
        checkOptimismPortal();
        checkProtocolVersions();
        checkSuperchainConfig(false);
    }

    /// @notice Asserts that the SystemConfig is setup correctly
    function checkSystemConfig() internal view {
        console.log("Running chain assertions on the SystemConfig");
        SystemConfig config = SystemConfig(prox.SystemConfig);

        ResourceMetering.ResourceConfig memory resourceConfig = config.resourceConfig();

        require(config.owner() == cfg.finalSystemOwner());
        require(config.overhead() == cfg.gasPriceOracleOverhead());
        require(config.scalar() == cfg.gasPriceOracleScalar());
        require(config.batcherHash() == bytes32(uint256(uint160(cfg.batchSenderAddress()))));
        require(config.gasLimit() == uint64(cfg.l2GenesisBlockGasLimit()));
        require(config.unsafeBlockSigner() == cfg.p2pSequencerAddress());
        // Check _config
        ResourceMetering.ResourceConfig memory rconfig = Constants.DEFAULT_RESOURCE_CONFIG();

        require(resourceConfig.maxResourceLimit == rconfig.maxResourceLimit);
        require(resourceConfig.elasticityMultiplier == rconfig.elasticityMultiplier);
        require(resourceConfig.baseFeeMaxChangeDenominator == rconfig.baseFeeMaxChangeDenominator);
        require(resourceConfig.systemTxMaxGas == rconfig.systemTxMaxGas);
        require(resourceConfig.minimumBaseFee == rconfig.minimumBaseFee);
        require(resourceConfig.maximumBaseFee == rconfig.maximumBaseFee);
        // Depends on start block being set to 0 in `initialize`
        uint256 cfgStartBlock = cfg.systemConfigStartBlock();
        require(config.startBlock() == (cfgStartBlock == 0 ? block.number : cfgStartBlock));
        require(config.batchInbox() == cfg.batchInboxAddress());
        // Check _addresses
        require(config.l1CrossDomainMessenger() == prox.L1CrossDomainMessenger);
        require(config.l1ERC721Bridge() == prox.L1ERC721Bridge);
        require(config.l1StandardBridge() == prox.L1StandardBridge);
        require(config.l2OutputOracle() == prox.L2OutputOracle);
        require(config.optimismPortal() == prox.OptimismPortal);
        require(config.optimismMintableERC20Factory() == prox.OptimismMintableERC20Factory);
    }

    /// @notice Asserts that the L1CrossDomainMessenger is setup correctly
    function checkL1CrossDomainMessenger() internal view {
        console.log("Running chain assertions on the L1CrossDomainMessenger");
        L1CrossDomainMessenger messenger = L1CrossDomainMessenger(prox.L1CrossDomainMessenger);

        require(address(messenger.OTHER_MESSENGER()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER);
        require(address(messenger.otherMessenger()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER);

        require(address(messenger.PORTAL()) == prox.OptimismPortal);
        require(address(messenger.portal()) == prox.OptimismPortal);
        require(address(messenger.superchainConfig()) == prox.SuperchainConfig);
        bytes32 xdmSenderSlot = vm.load(address(messenger), bytes32(uint256(204)));
        require(address(uint160(uint256(xdmSenderSlot))) == Constants.DEFAULT_L2_SENDER);
    }

    /// @notice Asserts that the L1StandardBridge is setup correctly
    function checkL1StandardBridge() internal view {
        console.log("Running chain assertions on the L1StandardBridge");
        L1StandardBridge bridge = L1StandardBridge(payable(prox.L1StandardBridge));

        require(address(bridge.MESSENGER()) == prox.L1CrossDomainMessenger);
        require(address(bridge.messenger()) == prox.L1CrossDomainMessenger);
        require(address(bridge.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE);
        require(address(bridge.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE);
        require(address(bridge.superchainConfig()) == prox.SuperchainConfig);
    }

    /// @notice Asserts that the L2OutputOracle is setup correctly
    function checkL2OutputOracle() internal view {
        console.log("Running chain assertions on the L2OutputOracle");
        L2OutputOracle oracle = L2OutputOracle(prox.L2OutputOracle);

        require(oracle.SUBMISSION_INTERVAL() == cfg.l2OutputOracleSubmissionInterval());
        require(oracle.submissionInterval() == cfg.l2OutputOracleSubmissionInterval());
        require(oracle.L2_BLOCK_TIME() == cfg.l2BlockTime());
        require(oracle.l2BlockTime() == cfg.l2BlockTime());
        require(oracle.PROPOSER() == cfg.l2OutputOracleProposer());
        require(oracle.proposer() == cfg.l2OutputOracleProposer());
        require(oracle.CHALLENGER() == cfg.l2OutputOracleChallenger());
        require(oracle.challenger() == cfg.l2OutputOracleChallenger());
        require(oracle.FINALIZATION_PERIOD_SECONDS() == cfg.finalizationPeriodSeconds());
        require(oracle.finalizationPeriodSeconds() == cfg.finalizationPeriodSeconds());
        require(oracle.startingBlockNumber() == cfg.l2OutputOracleStartingBlockNumber());
        require(oracle.startingTimestamp() == l2OutputOracleStartingTimestamp);
    }

    /// @notice Asserts that the OptimismMintableERC20Factory is setup correctly
    function checkOptimismMintableERC20Factory() internal view {
        console.log("Running chain assertions on the OptimismMintableERC20Factory");
        OptimismMintableERC20Factory factory = OptimismMintableERC20Factory(prox.OptimismMintableERC20Factory);

        require(factory.BRIDGE() == prox.L1StandardBridge);
        require(factory.bridge() == prox.L1StandardBridge);
    }

    /// @notice Asserts that the L1ERC721Bridge is setup correctly
    function checkL1ERC721Bridge() internal view {
        console.log("Running chain assertions on the L1ERC721Bridge");
        L1ERC721Bridge bridge = L1ERC721Bridge(prox.L1ERC721Bridge);

        require(address(bridge.OTHER_BRIDGE()) == Predeploys.L2_ERC721_BRIDGE);
        require(address(bridge.otherBridge()) == Predeploys.L2_ERC721_BRIDGE);

        require(address(bridge.MESSENGER()) == prox.L1CrossDomainMessenger);
        require(address(bridge.messenger()) == prox.L1CrossDomainMessenger);
        require(address(bridge.superchainConfig()) == prox.SuperchainConfig);
    }

    /// @notice Asserts the OptimismPortal is setup correctly
    function checkOptimismPortal() internal view {
        console.log("Running chain assertions on the OptimismPortal");

        OptimismPortal portal = OptimismPortal(payable(prox.OptimismPortal));

        address guardian = cfg.superchainConfigGuardian();

        require(address(portal.L2_ORACLE()) == prox.L2OutputOracle);
        require(address(portal.l2Oracle()) == prox.L2OutputOracle);
        require(address(portal.SYSTEM_CONFIG()) == prox.SystemConfig);
        require(address(portal.systemConfig()) == prox.SystemConfig);
        require(portal.GUARDIAN() == guardian);
        require(portal.guardian() == guardian);
        require(address(portal.superchainConfig()) == address(prox.SuperchainConfig));
        require(portal.paused() == SuperchainConfig(prox.SuperchainConfig).paused());
        require(portal.l2Sender() == Constants.DEFAULT_L2_SENDER);
    }

    /// @notice Asserts that the ProtocolVersions is setup correctly
    function checkProtocolVersions() internal view {
        console.log("Running chain assertions on the ProtocolVersions");
        ProtocolVersions versions = ProtocolVersions(prox.ProtocolVersions);
        require(versions.owner() == cfg.finalSystemOwner());
        require(ProtocolVersion.unwrap(versions.required()) == cfg.requiredProtocolVersion());
        require(ProtocolVersion.unwrap(versions.recommended()) == cfg.recommendedProtocolVersion());
    }

    /// @notice Asserts that the SuperchainConfig is setup correctly
    function checkSuperchainConfig(bool _isPaused) internal view {
        console.log("Running chain assertions on the SuperchainConfig");
        SuperchainConfig superchainConfig = SuperchainConfig(prox.SuperchainConfig);
        require(superchainConfig.guardian() == cfg.superchainConfigGuardian());
        require(superchainConfig.paused() == _isPaused);
    }
}
