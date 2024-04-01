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
    Types.ContractSet prox;
    DeployConfig public constant cfg =
        DeployConfig(address(uint160(uint256(keccak256(abi.encode("optimism.deployconfig"))))));
    uint256 l2OutputOracleStartingTimestamp = 1686068903;

    constructor() {
        prox = _getContractSet();

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
        checkSuperchainConfig();
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
    function checkSuperchainConfig() internal view {
        console.log("Running chain assertions on the SuperchainConfig");
        SuperchainConfig superchainConfig = SuperchainConfig(prox.SuperchainConfig);
        require(superchainConfig.guardian() == cfg.superchainConfigGuardian());
        require(superchainConfig.paused() == false);
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
