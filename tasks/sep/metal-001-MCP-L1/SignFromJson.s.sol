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
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

contract SignFromJson is OriginalSignFromJson {
    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "metal";

    // Known EOAs to exclude from safety checks.
    address constant l2OutputOracleProposer = 0x2D70F9A866dE34C0f738F8cb2AF1361b5aF18CAa;
    address constant l2OutputOracleChallenger = 0x45eFFbD799Ab49122eeEAB75B78D9C56A187F9A7;
    address constant systemConfigOwner = 0x23BA22Dd7923F3a3f2495bB32a6f3c9b9CD1EC6C;
    address constant batchSenderAddress = 0xdb80Eca386AC72a55510e33CF9CF7533e75916eE;
    address constant p2pSequencerAddress = 0x3C1A357c4c77843d34750dBee68C589ACB4F5f9B;
    address constant batchInboxAddress = 0x24567B64a86A4c966655fba6502a93dFb701E316;

    // Other data
    uint256 constant gasPriceOracleOverhead = 188; // cast call 0x5D63A8Dc2737cE771aa4a6510D063b6Ba2c4f6F2 "overhead()(uint)"
    uint256 constant gasPriceOracleScalar = 684000; // cast call 0x5D63A8Dc2737cE771aa4a6510D063b6Ba2c4f6F2 "scalar()(uint)"
    address constant superchainConfigGuardian = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B; // cast call 0xC2Be75506d5724086DEB7245bd260Cc9753911Be "guardian()(address)"
    address constant protocolVersionsOwner = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // cast call 0x79ADD5713B383DAa0a138d3C4780C7A1804a8090 "owner()(address)"
    uint256 constant systemConfigStartBlock = 5304055;
    AddressManager addressManager = AddressManager(0x394f844B9A0FC876935d1b0b791D9e94Ad905e8b);
    uint256 constant l2BlockTime = 2; // cast call 0x75a6B961c8da942Ee03CA641B09C322549f6FA98 "L2_BLOCK_TIME()(uint256)"
    uint256 constant l2OutputOracleSubmissionInterval = 180; // cast call 0x75a6B961c8da942Ee03CA641B09C322549f6FA98 "SUBMISSION_INTERVAL()(uint256)"
    uint256 constant finalizationPeriodSeconds = 604800; // cast call 0x75a6B961c8da942Ee03CA641B09C322549f6FA98 "FINALIZATION_PERIOD_SECONDS()(uint256)
    uint256 constant l2OutputOracleStartingTimestamp = 1708129620; // cast call 0x75a6B961c8da942Ee03CA641B09C322549f6FA98 "startingTimestamp()(uint)"
    uint256 constant l2OutputOracleStartingBlockNumber = 0; // TODO is this ok? cast call 0x75a6B961c8da942Ee03CA641B09C322549f6FA98 "startingBlockNumber()(uint)"
    uint256 constant l2GenesisBlockGasLimit = 30e6;
    uint256 constant requiredProtocolVersion = 0x0000000000000000000000000000000000000006000000000000000000000003; // cast call 0x79ADD5713B383DAa0a138d3C4780C7A1804a8090 "required()(bytes32)"
    uint256 constant recommendedProtocolVersion = 0x0000000000000000000000000000000000000006000000000000000000000003; // cast call 0x79ADD5713B383DAa0a138d3C4780C7A1804a8090 "recommended()(bytes32)"
    uint256 constant xdmSenderSlotNumber = 204; // Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L93-L99

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
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

        require(systemConfig.l2OutputOracle() == proxies.L2OutputOracle, "2000");
        require(systemConfig.l2OutputOracle().code.length != 0, "2001");
        require(EIP1967Helper.getImplementation(systemConfig.l2OutputOracle()).code.length != 0, "2002");

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

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkSystemConfig();
        checkL1CrossDomainMessenger();
        checkL1StandardBridge();
        checkL2OutputOracle();
        checkOptimismMintableERC20Factory();
        checkL1ERC721Bridge();
        checkOptimismPortal();
        checkProtocolVersions();
        checkSuperchainConfig();
        console.log("All assertions passed!");
    }

    // This method is not storage-layout-aware and therefore is not perfect. It may return erroneous
    // results for cases like packed slots, and silently show that things are okay when they are not.
    function isLikelyAddressThatShouldHaveCode(uint256 value) internal pure returns (bool) {
        // If out of range (fairly arbitrary lower bound), return false.
        if (value > type(uint160).max) return false;
        if (value < uint256(uint160(0x00000000fFFFffffffFfFfFFffFfFffFFFfFffff))) return false;

        // If the value is a L2 predeploy address it won't have code on this chain, so return false.
        if (
            value >= uint256(uint160(0x4200000000000000000000000000000000000000))
                && value <= uint256(uint160(0x420000000000000000000000000000000000FffF))
        ) return false;

        // Allow known EOAs.
        if (address(uint160(value)) == l2OutputOracleProposer) return false;
        if (address(uint160(value)) == l2OutputOracleChallenger) return false;
        if (address(uint160(value)) == systemConfigOwner) return false;
        if (address(uint160(value)) == batchSenderAddress) return false;
        if (address(uint160(value)) == p2pSequencerAddress) return false;
        if (address(uint160(value)) == batchInboxAddress) return false;

        // Otherwise, this value looks like an address that we'd expect to have code.
        return true;
    }

    function checkStateDiff(Vm.AccountAccess[] memory accesses) internal view {
        console.log("Running assertions on the state diff");

        for (uint256 i; i < accesses.length; i++) {
            Vm.AccountAccess memory access = accesses[i];
            require(
                access.account.code.length != 0, string.concat("Account has no code: ", vm.toString(access.account))
            );
            require(
                access.oldBalance == access.account.balance,
                string.concat("Unexpected balance change: ", vm.toString(access.account))
            );
            require(
                access.kind != VmSafe.AccountAccessKind.SelfDestruct,
                string.concat("Self-destructed account: ", vm.toString(access.account))
            );

            for (uint256 j; j < access.storageAccesses.length; j++) {
                Vm.StorageAccess memory storageAccess = access.storageAccesses[j];
                uint256 value = uint256(storageAccess.newValue);

                if (isLikelyAddressThatShouldHaveCode(value)) {
                    // Log account, slot, and value if there is no code.
                    if (address(uint160(value)).code.length == 0) {
                        string memory err = string.concat(
                            "Likely address in storage has no code\n",
                            "  account: ",
                            vm.toString(storageAccess.account),
                            "\n  slot:    ",
                            vm.toString(storageAccess.slot),
                            "\n  value:   ",
                            vm.toString(bytes32(value))
                        );
                        console.log(err);
                    }
                    // require(address(uint160(value)).code.length != 0, err);
                }

                require(
                    storageAccess.account.code.length != 0,
                    string.concat("Storage account has no code: ", vm.toString(storageAccess.account))
                );
                require(
                    !storageAccess.reverted,
                    string.concat("Storage access reverted: ", vm.toString(storageAccess.account))
                );
                require(
                    storageAccess.account.code.length != 0,
                    string.concat("Storage account has no code: ", vm.toString(storageAccess.account))
                );
                require(
                    !storageAccess.reverted,
                    string.concat("Storage access reverted: ", vm.toString(storageAccess.account))
                );
            }
        }
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/extra/addresses/mainnet/op.json
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
