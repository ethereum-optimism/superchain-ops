// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {AnchorStateRegistry} from "@eth-optimism-bedrock/src/dispute/AnchorStateRegistry.sol";
import {GameTypes, Hash} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DelayedWETH} from "@eth-optimism-bedrock/src/dispute/weth/DelayedWETH.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Constants, ResourceMetering} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {L1StandardBridge} from "@eth-optimism-bedrock/src/L1/L1StandardBridge.sol";
import {ProtocolVersion, ProtocolVersions} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
import {OptimismPortal2} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {L1CrossDomainMessenger} from "@eth-optimism-bedrock/src/L1/L1CrossDomainMessenger.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/src/L1/L1ERC721Bridge.sol";
import {AddressManager} from "@eth-optimism-bedrock/src/legacy/AddressManager.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {IGnosisSafe, Enum} from "@eth-optimism-bedrock/scripts/interfaces/IGnosisSafe.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    /// @notice Verify against https://sepolia.etherscan.io/address/0xC2Be75506d5724086DEB7245bd260Cc9753911Be 
    address constant superchainConfigGuardian = 0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E;

    /// @notice Verify with `cast call 0xf272670eb55e895584501d564AfEB048bEd26194 "unsafeBlockSigner()(address)"`
    address constant p2pSequencerAddress = 0xb830b99c95Ea32300039624Cb567d324D4b1D83C;

    /// @notice Verify with `cast call 0xf272670eb55e895584501d564AfEB048bEd26194 "batchInbox()(address)"` and https://docs.base.org/docs/base-contracts/
    address constant batchInboxAddress = 0xfF00000000000000000000000000000000084532;

    /// @notice Verify against https://docs.base.org/docs/base-contracts/
    address constant batchSenderAddress = 0x6CDEbe940BC0F26850285cacA097C11c33103E47;

    /// @notice Verify against lib/superchain-registry/superchain/extra/addresses/sepolia/base.json and https://docs.base.org/docs/base-contracts/
    address constant systemConfigOwner = 0x0fe884546476dDd290eC46318785046ef68a0BA9;

    uint256 constant l2GenesisBlockGasLimit = 45e6;

    /// @notice Verify with `cast call 0xf272670eb55e895584501d564AfEB048bEd26194 "overhead()(uint256)"`
    uint256 constant gasPriceOracleOverhead = 0;

    /// @notice Verify with `cast call 0xf272670eb55e895584501d564AfEB048bEd26194 "scalar()(bytes32)"`
    uint256 constant gasPriceOracleScalar = 0x010000000000000000000000000000000000000000000000000a118b0000044d;

    /// @notice Verify with `cast call 0xf272670eb55e895584501d564AfEB048bEd26194 "startBlock()(uint256)"`
    uint256 constant systemConfigStartBlock = 4370903;

    AddressManager addressManager = AddressManager(0x709c2B8ef4A9feFc629A8a2C1AF424Dc5BD6ad1B);

    address ownerSafe;

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();

        ownerSafe = vm.envAddress("OWNER_SAFE");
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory shouldHaveCodeExceptions = new address[](4);

        shouldHaveCodeExceptions[0] = systemConfigOwner;
        shouldHaveCodeExceptions[1] = batchSenderAddress;
        shouldHaveCodeExceptions[2] = p2pSequencerAddress;
        shouldHaveCodeExceptions[3] = batchInboxAddress;

        return shouldHaveCodeExceptions;
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/configs/sepolia/base.toml
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory addressesJson;

        // Read toml file
        string[] memory inputs = new string[](5);
        inputs[0] = "yq";
        inputs[1] = "--input-format=toml";
        inputs[2] = "-o";
        inputs[3] = "json";
        inputs[4] = "lib/superchain-registry/superchain/configs/sepolia/base.toml";
        addressesJson = string(vm.ffi(inputs));

        // Parse addresses from toml file
        _proxies.L1CrossDomainMessenger = stdJson.readAddress(addressesJson, "$.addresses.L1CrossDomainMessengerProxy");
        _proxies.L1StandardBridge = stdJson.readAddress(addressesJson, "$.addresses.L1StandardBridgeProxy");
        _proxies.OptimismMintableERC20Factory =
            stdJson.readAddress(addressesJson, "$.addresses.OptimismMintableERC20FactoryProxy");
        _proxies.OptimismPortal = stdJson.readAddress(addressesJson, "$.addresses.OptimismPortalProxy");
        _proxies.OptimismPortal2 = stdJson.readAddress(addressesJson, "$.addresses.OptimismPortalProxy");
        _proxies.SystemConfig = stdJson.readAddress(addressesJson, "$.addresses.SystemConfigProxy");
        _proxies.L1ERC721Bridge = stdJson.readAddress(addressesJson, "$.addresses.L1ERC721BridgeProxy");

        // Read and parse superchain.toml
        inputs[4] = "lib/superchain-registry/superchain/configs/sepolia/superchain.toml";
        addressesJson = string(vm.ffi(inputs));

        _proxies.ProtocolVersions = stdJson.readAddress(addressesJson, "$.protocol_versions_addr");
        _proxies.SuperchainConfig = stdJson.readAddress(addressesJson, "$.superchain_config_addr");

        // Add the remaining proxies from the env config, which are the proxies for the Fault Proof contracts
        _proxies.AnchorStateRegistry = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        _proxies.DisputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        _proxies.DelayedWETH = vm.envAddress("DELAYED_WETH_PROXY");
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkSemvers();
        checkStateDiff(accesses);
        checkSystemConfig();
        checkOptimismPortal();
        checkAnchorStateRegistry();
        checkDelayedWETH();
        checkDisputeGameFactory();
        checkFaultDisputeGame();
        checkPermissionedDisputeGame();
        console.log("All assertions passed!");
    }

    function checkSemvers() internal view {
        // These are the expected semvers based on the `op-contracts/v1.4.0-rc.4` release.
        // https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.4.0-rc.4
        require(ISemver(proxies.L1CrossDomainMessenger).version().eq("2.3.0"), "semver-100");
        require(ISemver(proxies.L1ERC721Bridge).version().eq("2.1.0"), "semver-700");
        require(ISemver(proxies.L1StandardBridge).version().eq("2.1.0"), "semver-200");
        require(ISemver(proxies.OptimismMintableERC20Factory).version().eq("1.9.0"), "semver-400");
        require(ISemver(proxies.OptimismPortal).version().eq("3.10.0"), "semver-500");
        require(ISemver(proxies.SystemConfig).version().eq("2.2.0"), "semver-600");
        require(ISemver(proxies.ProtocolVersions).version().eq("1.0.0"), "semver-800");
        require(ISemver(proxies.SuperchainConfig).version().eq("1.1.0"), "semver-900");
        require(ISemver(proxies.DisputeGameFactory).version().eq("1.0.0"), "semver-1000");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](3);
        allowed[0] = proxies.SystemConfig;
        allowed[1] = proxies.OptimismPortal;
        allowed[2] = ownerSafe;
    }

    /// @notice Asserts that the SystemConfig is setup correctly
    ///         Assertions are similar to the base-001-MCP-L1 upgrade
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

        require(systemConfig.optimismPortal() == proxies.OptimismPortal, "2100");
        require(systemConfig.optimismPortal().code.length != 0, "2101");
        require(EIP1967Helper.getImplementation(systemConfig.optimismPortal()).code.length != 0, "2102");

        require(systemConfig.optimismMintableERC20Factory() == proxies.OptimismMintableERC20Factory, "2200");
        require(systemConfig.optimismMintableERC20Factory().code.length != 0, "2201");
        require(EIP1967Helper.getImplementation(systemConfig.optimismMintableERC20Factory()).code.length != 0, "2202");

        require(systemConfig.disputeGameFactory() == proxies.DisputeGameFactory, "2300");
        require(systemConfig.disputeGameFactory().code.length != 0, "2301");
        require(EIP1967Helper.getImplementation(systemConfig.disputeGameFactory()).code.length != 0, "2302");

        // Ensure that the old l2outputoracle slot is cleared
        bytes32 l2OutputOracleSlot =
            vm.load(address(systemConfig), bytes32(uint256(keccak256("systemconfig.l2outputoracle")) - 1));
        require(address(uint160(uint256(l2OutputOracleSlot))) == address(0), "2400");
    }

    function checkOptimismPortal() internal view {
        console.log("Running chain assertions on the OptimismPortal");

        // NOTE: proxies.OptimismPortal2 == proxies.OptimismPortal
        require(proxies.OptimismPortal.code.length != 0, "5700");
        require(EIP1967Helper.getImplementation(proxies.OptimismPortal).code.length != 0, "5701");

        OptimismPortal2 portalToCheck = OptimismPortal2(payable(proxies.OptimismPortal));

        require(address(portalToCheck.disputeGameFactory()) == proxies.DisputeGameFactory, "5800");
        require(address(portalToCheck.disputeGameFactory()).code.length != 0, "5801");
        require(EIP1967Helper.getImplementation(address(portalToCheck.disputeGameFactory())).code.length != 0, "5802");

        checkOptimismPortal2();
    }

    // @notice checkOptimismPortal is broken up to avoid stack too deep solc errors
    function checkOptimismPortal2() internal view {
        OptimismPortal2 portalToCheck = OptimismPortal2(payable(proxies.OptimismPortal));
        require(address(portalToCheck.systemConfig()) == proxies.SystemConfig, "5900");
        require(address(portalToCheck.systemConfig()).code.length != 0, "5901");
        require(EIP1967Helper.getImplementation(address(portalToCheck.systemConfig())).code.length != 0, "5902");

        require(portalToCheck.guardian() == superchainConfigGuardian, "6000");
        require(portalToCheck.guardian().code.length != 0, "6001"); // This is a Safe, no need to check the implementation.

        require(address(portalToCheck.superchainConfig()) == address(proxies.SuperchainConfig), "6100");
        require(address(portalToCheck.superchainConfig()).code.length != 0, "6101");
        require(EIP1967Helper.getImplementation(address(portalToCheck.superchainConfig())).code.length != 0, "6102");

        require(portalToCheck.paused() == SuperchainConfig(proxies.SuperchainConfig).paused(), "6200");

        require(portalToCheck.l2Sender() == Constants.DEFAULT_L2_SENDER, "6300");

        require(portalToCheck.respectedGameType().raw() == GameTypes.CANNON.raw(), "6400");

        require(portalToCheck.respectedGameTypeUpdatedAt() != 0, "6500");
    }

    function checkAnchorStateRegistry() internal view {
        console.log("Running chain assertions on the AnchorStateRegistry");

        require(proxies.AnchorStateRegistry.code.length != 0, "6600");
        require(EIP1967Helper.getImplementation(proxies.AnchorStateRegistry).code.length != 0, "6601");
        require(EIP1967Helper.getImplementation(proxies.AnchorStateRegistry) == vm.envAddress("ANCHOR_STATE_REGISTRY_IMPL"), "6602");

        AnchorStateRegistry anchorStateRegistry = AnchorStateRegistry(proxies.AnchorStateRegistry);

        require(ISemver(proxies.AnchorStateRegistry).version().eq("1.0.0"), "6700");

        require(address(anchorStateRegistry.disputeGameFactory()) == proxies.DisputeGameFactory, "6800");
        require(address(anchorStateRegistry.disputeGameFactory()).code.length != 0, "6801");
        require(EIP1967Helper.getImplementation(address(anchorStateRegistry.disputeGameFactory())).code.length != 0, "6802");
    }

    function checkDelayedWETH() internal view {
        console.log("Running chain assertions on DelayedWETH");

        require(proxies.DelayedWETH.code.length != 0, "7000");
        require(EIP1967Helper.getImplementation(proxies.DelayedWETH).code.length != 0, "7001");
        require(EIP1967Helper.getImplementation(proxies.DelayedWETH) == vm.envAddress("DELAYED_WETH_IMPL"), "7002");

        DelayedWETH delayedWETH = DelayedWETH(payable(proxies.DelayedWETH));
        require(ISemver(proxies.DelayedWETH).version().eq("1.0.0"), "7100");
        require(delayedWETH.owner() == systemConfigOwner, "7101");

        require(address(delayedWETH.config()) == proxies.SuperchainConfig, "7200");
        require(address(delayedWETH.config()).code.length != 0, "7201");
        require(EIP1967Helper.getImplementation(address(delayedWETH.config())).code.length != 0, "7202");
    }

    function checkDisputeGameFactory() internal view {
        console.log("Running chain assertions on the DisputeGameFactory");

        require(proxies.DisputeGameFactory.code.length != 0, "7300");
        require(EIP1967Helper.getImplementation(proxies.DisputeGameFactory).code.length != 0, "7301");
        require(EIP1967Helper.getImplementation(proxies.DisputeGameFactory) == vm.envAddress("DISPUTE_GAME_FACTORY_IMPL"), "7302");

        DisputeGameFactory disputeGameFactory = DisputeGameFactory(proxies.DisputeGameFactory);
        require(ISemver(proxies.DisputeGameFactory).version().eq("1.0.0"), "7400");

        require(disputeGameFactory.owner() == systemConfigOwner, "7500");

        require(disputeGameFactory.initBonds(GameTypes.CANNON) == vm.envUint("INIT_ETH_BOND"), "7600");
        require(disputeGameFactory.initBonds(GameTypes.PERMISSIONED_CANNON) == vm.envUint("INIT_ETH_BOND"), "7601");

        require(address(disputeGameFactory.gameImpls(GameTypes.CANNON)) == vm.envAddress("FAULT_DISPUTE_GAME"), "7700");
        require(address(disputeGameFactory.gameImpls(GameTypes.CANNON)).code.length != 0, "7701");
        require(address(disputeGameFactory.gameImpls(GameTypes.PERMISSIONED_CANNON)) == vm.envAddress("PERMISSIONED_DISPUTE_GAME"), "7702");
        require(address(disputeGameFactory.gameImpls(GameTypes.PERMISSIONED_CANNON)).code.length != 0, "7703");
    }

    function checkFaultDisputeGame() internal view {
        console.log("Running chain assertions on the FaultDisputeGame");

        require(vm.envAddress("FAULT_DISPUTE_GAME").code.length != 0, "7800");

        FaultDisputeGame fdg = FaultDisputeGame(vm.envAddress("FAULT_DISPUTE_GAME"));
        require(ISemver(vm.envAddress("FAULT_DISPUTE_GAME")).version().eq("1.2.0"), "7900");

        require(fdg.absolutePrestate().raw() == vm.envBytes32("ABS_PRESTATE"), "8000");
        require(fdg.splitDepth() == vm.envUint("SPLIT_DEPTH"), "8001");
        require(fdg.maxGameDepth() == vm.envUint("MAX_DEPTH"), "8002");
        require(fdg.maxClockDuration().raw() == vm.envUint("MAX_CLOCK_DURATION"), "8003");
        require(fdg.clockExtension().raw() == vm.envUint("CLOCK_EXTENSION"), "8004");
        require(fdg.l2ChainId() == vm.envUint("CHAIN_ID"), "8005");

        require(address(fdg.vm()) == vm.envAddress("MIPS_VM"),  "8100");
        require(address(fdg.vm()).code.length != 0, "8101");

        require(address(fdg.weth()) == proxies.DelayedWETH, "8200");
        require(address(fdg.weth()).code.length != 0, "8201");
    }

    function checkPermissionedDisputeGame() internal view {
        console.log("Running chain assertions on the PermissionedDisputeGame");

        require(vm.envAddress("PERMISSIONED_DISPUTE_GAME").code.length != 0, "8300");

        PermissionedDisputeGame pdg = PermissionedDisputeGame(vm.envAddress("PERMISSIONED_DISPUTE_GAME"));
        require(ISemver(vm.envAddress("PERMISSIONED_DISPUTE_GAME")).version().eq("1.2.0"), "8400");

        require(pdg.absolutePrestate().raw() == vm.envBytes32("ABS_PRESTATE"), "8500");
        require(pdg.splitDepth() == vm.envUint("SPLIT_DEPTH"), "8501");
        require(pdg.maxGameDepth() == vm.envUint("MAX_DEPTH"), "8502");
        require(pdg.maxClockDuration().raw() == vm.envUint("MAX_CLOCK_DURATION"), "8503");
        require(pdg.clockExtension().raw() == vm.envUint("CLOCK_EXTENSION"), "8504");
        require(pdg.l2ChainId() == vm.envUint("CHAIN_ID"), "8505");

        require(address(pdg.vm()) == vm.envAddress("MIPS_VM"),  "8600");
        require(address(pdg.vm()).code.length != 0, "8601");

        require(address(pdg.weth()) == proxies.DelayedWETH, "8700");
        require(address(pdg.weth()).code.length != 0, "8701");

        require(pdg.proposer() == vm.envAddress("PDG_PROPOSER"), "8800");
        require(pdg.challenger() == vm.envAddress("PDG_CHALLENGER"), "8801");
    }
}
