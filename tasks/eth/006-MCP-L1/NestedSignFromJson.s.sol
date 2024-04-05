// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
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
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    /// @notice Verify against https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
    address constant finalSystemOwner = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#guardian
    address constant superchainConfigGuardian = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L7
    uint256 constant l2BlockTime = 2;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L12
    address constant p2pSequencerAddress = 0xAAAA45d9549EDA09E70937013520214382Ffc4A2;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L13
    address constant batchInboxAddress = 0xFF00000000000000000000000000000000000010;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#batcher
    address constant batchSenderAddress = 0x6887246668a3b87F54DeB3b94Ba47a6f63F32985;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L15
    uint256 constant l2OutputOracleSubmissionInterval = 1800;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L16
    uint256 constant l2OutputOracleStartingTimestamp = 1686068903;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L17
    uint256 constant l2OutputOracleStartingBlockNumber = 105235063;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#proposer
    address constant l2OutputOracleProposer = 0x473300df21D047806A082244b417f96b32f13A33;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#challenger
    address constant l2OutputOracleChallenger = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L20
    uint256 constant finalizationPeriodSeconds = 604800;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L35
    uint256 constant l2GenesisBlockGasLimit = 0x1c9c380;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L37
    uint256 constant gasPriceOracleOverhead = 0;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L38
    uint256 constant gasPriceOracleScalar = 0;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L44
    uint256 constant systemConfigStartBlock = 17422444;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L45
    uint256 constant requiredProtocolVersion = 0x0000000000000000000000000000000000000003000000010000000000000000;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L46
    uint256 constant recommendedProtocolVersion = 0x0000000000000000000000000000000000000003000000010000000000000000;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L93-L99
    uint256 constant xdmSenderSlotNumber = 204;

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    /// @notice Asserts that the SystemConfig is setup correctly
    function checkSystemConfig() internal view {
        console.log("Running chain assertions on the SystemConfig");

        require(proxies.SystemConfig.code.length != 0, "200");

        require(EIP1967Helper.getImplementation(proxies.SystemConfig).code.length != 0, "201");

        SystemConfig configToCheck = SystemConfig(proxies.SystemConfig);

        ResourceMetering.ResourceConfig memory resourceConfigToCheck = configToCheck.resourceConfig();

        require(configToCheck.owner() == superchainConfigGuardian, "300");

        require(configToCheck.overhead() == gasPriceOracleOverhead, "400");

        require(configToCheck.scalar() == gasPriceOracleScalar, "500");

        require(configToCheck.batcherHash() == bytes32(uint256(uint160(batchSenderAddress))), "600");

        require(configToCheck.gasLimit() == uint64(l2GenesisBlockGasLimit), "700");

        require(configToCheck.unsafeBlockSigner() == p2pSequencerAddress, "800");

        // Check _config
        require(
            keccak256(abi.encode(resourceConfigToCheck)) == keccak256(abi.encode(Constants.DEFAULT_RESOURCE_CONFIG())),
            "900"
        );

        require(configToCheck.startBlock() == systemConfigStartBlock, "1500");

        require(configToCheck.batchInbox() == batchInboxAddress, "1600");

        // Check _addresses
        require(configToCheck.l1CrossDomainMessenger() == proxies.L1CrossDomainMessenger, "1700");
        require(configToCheck.l1CrossDomainMessenger().code.length != 0, "1701");
        require(EIP1967Helper.getImplementation(configToCheck.l1CrossDomainMessenger()).code.length != 0, "1702");

        require(configToCheck.l1ERC721Bridge() == proxies.L1ERC721Bridge, "1800");
        require(configToCheck.l1ERC721Bridge().code.length != 0, "1801");
        require(EIP1967Helper.getImplementation(configToCheck.l1ERC721Bridge()).code.length != 0, "1802");

        require(configToCheck.l1StandardBridge() == proxies.L1StandardBridge, "1900");
        require(configToCheck.l1StandardBridge().code.length != 0, "1901");
        require(EIP1967Helper.getImplementation(configToCheck.l1StandardBridge()).code.length != 0, "1902");

        require(configToCheck.l2OutputOracle() == proxies.L2OutputOracle, "2000");
        require(configToCheck.l2OutputOracle().code.length != 0, "2001");
        require(EIP1967Helper.getImplementation(configToCheck.l2OutputOracle()).code.length != 0, "2002");

        require(configToCheck.optimismPortal() == proxies.OptimismPortal, "2100");
        require(configToCheck.optimismPortal().code.length != 0, "2101");
        require(EIP1967Helper.getImplementation(configToCheck.optimismPortal()).code.length != 0, "2102");

        require(configToCheck.optimismMintableERC20Factory() == proxies.OptimismMintableERC20Factory, "2200");
        require(configToCheck.optimismMintableERC20Factory().code.length != 0, "2201");
        require(EIP1967Helper.getImplementation(configToCheck.optimismMintableERC20Factory()).code.length != 0, "2202");
    }

    /// @notice Asserts that the L1CrossDomainMessenger is setup correctly
    function checkL1CrossDomainMessenger() internal view {
        console.log("Running chain assertions on the L1CrossDomainMessenger");

        require(proxies.L1CrossDomainMessenger.code.length != 0, "2300");

        require(EIP1967Helper.getImplementation(proxies.L1CrossDomainMessenger).code.length != 0, "2301");

        L1CrossDomainMessenger messengerToCheck = L1CrossDomainMessenger(proxies.L1CrossDomainMessenger);

        require(address(messengerToCheck.OTHER_MESSENGER()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER, "2400");
        require(address(messengerToCheck.otherMessenger()) == Predeploys.L2_CROSS_DOMAIN_MESSENGER, "2500");
        require(address(messengerToCheck.otherMessenger()).code.length != 0, "2501");
        require(EIP1967Helper.getImplementation(address(messengerToCheck.otherMessenger())).code.length != 0, "2502");

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
        console.log("Running chain assertions on the L1StandardBridge");

        require(proxies.L1StandardBridge.code.length != 0, "2901");

        require(EIP1967Helper.getImplementation(proxies.L1StandardBridge).code.length != 0, "2901");

        L1StandardBridge bridgeToCheck = L1StandardBridge(payable(proxies.L1StandardBridge));

        require(address(bridgeToCheck.MESSENGER()) == proxies.L1CrossDomainMessenger, "3000");
        require(address(bridgeToCheck.messenger()) == proxies.L1CrossDomainMessenger, "3100");
        require(address(bridgeToCheck.messenger()).code.length != 0, "3101");
        require(EIP1967Helper.getImplementation(address(bridgeToCheck.messenger())).code.length != 0, "3102");

        require(address(bridgeToCheck.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE, "3200");
        require(address(bridgeToCheck.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE, "3300");
        require(address(bridgeToCheck.otherBridge()).code.length != 0, "3302");
        require(EIP1967Helper.getImplementation(address(bridgeToCheck.otherBridge())).code.length != 0, "3203");

        require(address(bridgeToCheck.superchainConfig()) == proxies.SuperchainConfig, "3400");
        require(address(bridgeToCheck.superchainConfig()).code.length != 0, "3401");
        require(EIP1967Helper.getImplementation(address(bridgeToCheck.superchainConfig())).code.length != 0, "3402");
    }

    /// @notice Asserts that the L2OutputOracle is setup correctly
    function checkL2OutputOracle() internal view {
        console.log("Running chain assertions on the L2OutputOracle");

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
        console.log("Running chain assertions on the OptimismMintableERC20Factory");

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
        console.log("Running chain assertions on the L1ERC721Bridge");

        require(proxies.L1ERC721Bridge.code.length != 0, "5100");

        require(EIP1967Helper.getImplementation(proxies.L1ERC721Bridge).code.length != 0, "5101");

        L1ERC721Bridge bridgeToCheck = L1ERC721Bridge(proxies.L1ERC721Bridge);

        require(address(bridgeToCheck.OTHER_BRIDGE()) == Predeploys.L2_ERC721_BRIDGE, "5200");
        require(address(bridgeToCheck.otherBridge()) == Predeploys.L2_ERC721_BRIDGE, "5300");
        require(address(bridgeToCheck.otherBridge()).code.length != 0, "5301");
        require(EIP1967Helper.getImplementation(address(bridgeToCheck.otherBridge())).code.length != 0, "5302");

        require(address(bridgeToCheck.MESSENGER()) == proxies.L1CrossDomainMessenger, "5400");
        require(address(bridgeToCheck.messenger()) == proxies.L1CrossDomainMessenger, "5500");
        require(address(bridgeToCheck.messenger()).code.length != 0, "5502");
        require(EIP1967Helper.getImplementation(address(bridgeToCheck.messenger())).code.length != 0, "5503");

        require(address(bridgeToCheck.superchainConfig()) == proxies.SuperchainConfig, "5600");
        require(address(bridgeToCheck.superchainConfig()).code.length != 0, "5601");
        require(EIP1967Helper.getImplementation(address(bridgeToCheck.superchainConfig())).code.length != 0, "5603");
    }

    /// @notice Asserts the OptimismPortal is setup correctly
    function checkOptimismPortal() internal view {
        console.log("Running chain assertions on the OptimismPortal");

        require(proxies.OptimismPortal.code.length != 0, "5700");

        require(EIP1967Helper.getImplementation(proxies.OptimismPortal).code.length != 0, "5701");

        OptimismPortal portalToCheck = OptimismPortal(payable(proxies.OptimismPortal));

        require(address(portalToCheck.L2_ORACLE()) == proxies.L2OutputOracle, "5800");
        require(address(portalToCheck.l2Oracle()) == proxies.L2OutputOracle, "5900");
        require(address(portalToCheck.l2Oracle()).code.length != 0, "5901");
        require(EIP1967Helper.getImplementation(address(portalToCheck.l2Oracle())).code.length != 0, "5902");

        require(address(portalToCheck.SYSTEM_CONFIG()) == proxies.SystemConfig, "6000");
        require(address(portalToCheck.systemConfig()) == proxies.SystemConfig, "6100");
        require(address(portalToCheck.systemConfig()).code.length != 0, "6101");
        require(EIP1967Helper.getImplementation(address(portalToCheck.systemConfig())).code.length != 0, "6102");

        require(portalToCheck.GUARDIAN() == superchainConfigGuardian, "6200");
        require(portalToCheck.guardian() == superchainConfigGuardian, "6300");
        require(portalToCheck.guardian().code.length != 0, "6301");
        require(EIP1967Helper.getImplementation(portalToCheck.guardian()).code.length != 0, "6302");

        require(address(portalToCheck.superchainConfig()) == address(proxies.SuperchainConfig), "6400");
        require(address(portalToCheck.superchainConfig()).code.length != 0, "6401");
        require(EIP1967Helper.getImplementation(address(portalToCheck.superchainConfig())).code.length != 0, "6402");

        require(portalToCheck.paused() == SuperchainConfig(proxies.SuperchainConfig).paused(), "6500");

        require(portalToCheck.l2Sender() == Constants.DEFAULT_L2_SENDER, "6600");
    }

    /// @notice Asserts that the ProtocolVersions is setup correctly
    function checkProtocolVersions() internal view {
        console.log("Running chain assertions on the ProtocolVersions");

        require(proxies.ProtocolVersions.code.length != 0, "6700");

        require(EIP1967Helper.getImplementation(proxies.ProtocolVersions).code.length != 0, "6701");

        ProtocolVersions protocolVersionsToCheck = ProtocolVersions(proxies.ProtocolVersions);

        require(protocolVersionsToCheck.owner() == superchainConfigGuardian, "6800");

        require(ProtocolVersion.unwrap(protocolVersionsToCheck.required()) == requiredProtocolVersion, "6900");

        require(ProtocolVersion.unwrap(protocolVersionsToCheck.recommended()) == recommendedProtocolVersion, "7000");
    }

    /// @notice Asserts that the SuperchainConfig is setup correctly
    function checkSuperchainConfig() internal view {
        console.log("Running chain assertions on the SuperchainConfig");

        require(proxies.SuperchainConfig.code.length != 0, "7100");

        require(EIP1967Helper.getImplementation(proxies.SuperchainConfig).code.length != 0, "7101");

        SuperchainConfig superchainConfigToCheck = SuperchainConfig(proxies.SuperchainConfig);

        require(superchainConfigToCheck.guardian() == superchainConfigGuardian, "7200");
        require(superchainConfigToCheck.guardian().code.length != 0, "7201");
        require(EIP1967Helper.getImplementation(superchainConfigToCheck.guardian()).code.length != 0, "7202");

        require(superchainConfigToCheck.paused() == false, "7300");
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
        string memory addressesJson;

        // Read addresses json
        try vm.readFile(
            string.concat(vm.projectRoot(), "/lib/superchain-registry/superchain/extra/addresses/mainnet/op.json")
        ) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert("Failed to read lib/superchain-registry/superchain/extra/addresses/mainnet/op.json");
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
        inputs[3] = "lib/superchain-registry/superchain/configs/mainnet/superchain.yaml";

        addressesJson = string(vm.ffi(inputs));

        _proxies.ProtocolVersions = stdJson.readAddress(addressesJson, "$.protocol_versions_addr");
        _proxies.SuperchainConfig = stdJson.readAddress(addressesJson, "$.superchain_config_addr");
    }
}
