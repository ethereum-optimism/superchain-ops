// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {CouncilFoundationNestedSign} from "script/verification/CouncilFoundationNestedSign.s.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";
import {BytecodeComparison} from "src/libraries/BytecodeComparison.sol";
import {GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {IProxy} from "@eth-optimism-bedrock/interfaces/universal/IProxy.sol";
import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {IDisputeGameFactory} from "@eth-optimism-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import {IPermissionedDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IPermissionedDisputeGame.sol";
import {IAnchorStateRegistry} from "@eth-optimism-bedrock/interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "@eth-optimism-bedrock/interfaces/dispute/IDelayedWETH.sol";
import {IOptimismPortal2} from "@eth-optimism-bedrock/interfaces/L1/IOptimismPortal2.sol";
import {ISystemConfig} from "@eth-optimism-bedrock/interfaces/L1/ISystemConfig.sol";
import {IL1CrossDomainMessenger} from "@eth-optimism-bedrock/interfaces/L1/IL1CrossDomainMessenger.sol";
import {IL1StandardBridge} from "@eth-optimism-bedrock/interfaces/L1/IL1StandardBridge.sol";
import {IL1ERC721Bridge} from "@eth-optimism-bedrock/interfaces/L1/IL1ERC721Bridge.sol";
import {IAddressManager} from "@eth-optimism-bedrock/interfaces/legacy/IAddressManager.sol";
import {IL1ChugSplashProxy} from "@eth-optimism-bedrock/interfaces/legacy/IL1ChugSplashProxy.sol";
import {IOptimismMintableERC20Factory} from
    "@eth-optimism-bedrock/interfaces/universal/IOptimismMintableERC20Factory.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";

interface ISystemConfigLegacy is ISystemConfig {
    function l2OutputOracle() external view returns (address);
}

contract NestedSignFromJson is OriginalNestedSignFromJson, CouncilFoundationNestedSign, SuperchainRegistry {
    using AccountAccessParser for VmSafe.AccountAccess[];

    /// @notice Expected address for the AnchorStateRegistry proxy.
    IAnchorStateRegistry expectedAnchorStateRegistryProxy =
        IAnchorStateRegistry(vm.envAddress("EXPECTED_ANCHOR_STATE_REGISTRY_PROXY"));

    /// @notice Expected address for the AnchorStateRegistry implementation.
    IAnchorStateRegistry expectedAnchorStateRegistryImpl =
        IAnchorStateRegistry(vm.envAddress("EXPECTED_ANCHOR_STATE_REGISTRY_IMPL"));

    /// @notice OP Mainnet address for the AnchorStateRegistry implementation for comparison.
    IAnchorStateRegistry comparisonAnchorStateRegistryImpl =
        IAnchorStateRegistry(vm.envAddress("COMPARISON_ANCHOR_STATE_REGISTRY_IMPL"));

    /// @notice Expected address for the PermissionedDisputeGame implementation.
    IPermissionedDisputeGame expectedPermissionedDisputeGameImpl =
        IPermissionedDisputeGame(vm.envAddress("EXPECTED_PERMISSIONED_DISPUTE_GAME_IMPL"));

    /// @notice OP Mainnet address for the PermissionedDisputeGame implementation for comparison.
    IPermissionedDisputeGame comparisonPermissionedDisputeGameImpl =
        IPermissionedDisputeGame(vm.envAddress("COMPARISON_PERMISSIONED_DISPUTE_GAME_IMPL"));

    /// @notice Expected address for the DelayedWETH proxy.
    IDelayedWETH expectedDelayedWETHProxy =
        IDelayedWETH(payable(vm.envAddress("EXPECTED_PERMISSIONED_DELAYED_WETH_PROXY")));

    /// @notice Expected address for the DisputeGameFactory proxy.
    IDisputeGameFactory expectedDisputeGameFactoryProxy =
        IDisputeGameFactory(vm.envAddress("EXPECTED_DISPUTE_GAME_FACTORY_PROXY"));

    /// @notice Expected prestate.
    bytes32 expectedPrestate = vm.envBytes32("EXPECTED_PRESTATE");

    /// @notice Expected guardian address.
    address expectedGuardian = vm.envAddress("EXPECTED_GUARDIAN");

    /// @notice Script constructor.
    constructor() SuperchainRegistry("mainnet", "zora", "v1.8.0-rc.4") {}

    /// @notice Sets up the script.
    function setUp() public view {
        _preCheck();
    }

    /// @notice Returns addresses that are allowed to not have any code.
    /// @return allowed_ The addresses that are allowed to not have any code.
    function getCodeExceptions() internal view override returns (address[] memory allowed_) {
        allowed_ = new address[](3);
        allowed_[0] = address(uint160(uint256(ISystemConfig(proxies.SystemConfig).batcherHash())));
        allowed_[1] = ISystemConfig(proxies.SystemConfig).unsafeBlockSigner();
        allowed_[2] = ISystemConfig(proxies.SystemConfig).batchInbox();
    }

    /// @notice Returns addresses that are allowed to access storage.
    /// @return allowed_ The addresses that are allowed to access storage.
    function getAllowedStorageAccess() internal view override returns (address[] memory allowed_) {
        allowed_ = new address[](11);
        allowed_[0] = vm.envAddress("OWNER_SAFE");
        allowed_[1] = vm.envAddress("FOUNDATION_SAFE");
        allowed_[2] = vm.envAddress("COUNCIL_SAFE");
        allowed_[3] = vm.envAddress("LIVENESS_GUARD");
        allowed_[4] = proxies.OptimismPortal;
        allowed_[5] = proxies.SystemConfig;
        allowed_[6] = addressManager;
        allowed_[7] = proxies.L1CrossDomainMessenger;
        allowed_[8] = proxies.L1StandardBridge;
        allowed_[9] = proxies.L1ERC721Bridge;
        allowed_[10] = proxies.OptimismMintableERC20Factory;
    }

    /// @notice Checks correctness prior to execution.
    function _preCheck() internal view {
        console.log("Running pre-deploy assertions");
        checkInputJson();
        console.log("All assertions passed!");
    }

    /// @notice Checks correctness after execution.
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkOptimismPortal();
        checkSystemConfig();
        checkL1CrossDomainMessenger();
        checkL1StandardBridge();
        checkL1ERC721Bridge();
        checkOptimismMintableERC20Factory();
        checkAnchorStateRegistry();
        checkDelayedWETH();
        checkDisputeGameFactory();
        checkPermissionedDisputeGame();
        console.log("All assertions passed!");

        accesses.decodeAndPrint(address(0), bytes32(0));
    }

    /// @notice Checks the input to the script.
    function checkInputJson() internal view {
        string memory inputJson;
        string memory path = "/tasks/eth/zora-002-fp-upgrade/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        // Check that the OptimismPortal proxy and implementation addresses are correct.
        require(
            stdJson.readAddress(inputJson, "$.transactions[3].contractInputsValues._proxy")
                == address(proxies.OptimismPortal),
            "checkInput-20"
        );
        require(
            stdJson.readAddress(inputJson, "$.transactions[3].contractInputsValues._implementation")
                == standardVersions.OptimismPortal.implementation,
            "checkInput-40"
        );

        // Check that the SystemConfig proxy and implementation addresses are correct.
        require(
            stdJson.readAddress(inputJson, "$.transactions[9].contractInputsValues._proxy")
                == address(proxies.SystemConfig),
            "checkInput-60"
        );
        require(
            stdJson.readAddress(inputJson, "$.transactions[9].contractInputsValues._implementation")
                == standardVersions.SystemConfig.implementation,
            "checkInput-80"
        );

        // Check that the L1CrossDomainMessenger proxy and implementation addresses are correct.
        require(
            stdJson.readAddress(inputJson, "$.transactions[12].contractInputsValues._proxy")
                == address(proxies.L1CrossDomainMessenger),
            "checkInput-100"
        );
        require(
            stdJson.readAddress(inputJson, "$.transactions[12].contractInputsValues._implementation")
                == standardVersions.L1CrossDomainMessenger.implementation,
            "checkInput-120"
        );

        // Check that the L1StandardBridge proxy and implementation addresses are correct
        require(
            stdJson.readAddress(inputJson, "$.transactions[16].contractInputsValues._proxy")
                == address(proxies.L1StandardBridge),
            "checkInput-140"
        );
        require(
            stdJson.readAddress(inputJson, "$.transactions[16].contractInputsValues._implementation")
                == standardVersions.L1StandardBridge.implementation,
            "checkInput-160"
        );

        // Check that the L1ERC721Bridge proxy and implementation addresses are correct
        require(
            stdJson.readAddress(inputJson, "$.transactions[20].contractInputsValues._proxy")
                == address(proxies.L1ERC721Bridge),
            "checkInput-180"
        );
        require(
            stdJson.readAddress(inputJson, "$.transactions[20].contractInputsValues._implementation")
                == standardVersions.L1ERC721Bridge.implementation,
            "checkInput-200"
        );

        // Check that the OptimismMintableERC20Factory proxy and implementation addresses are correct
        require(
            stdJson.readAddress(inputJson, "$.transactions[22].contractInputsValues._proxy")
                == address(proxies.OptimismMintableERC20Factory),
            "checkInput-220"
        );
        require(
            stdJson.readAddress(inputJson, "$.transactions[22].contractInputsValues._implementation")
                == standardVersions.OptimismMintableERC20Factory.implementation,
            "checkInput-240"
        );
    }

    /// @notice Checks that the OptimismPortal was handled correctly.
    function checkOptimismPortal() internal {
        // Load contract into correct type.
        IOptimismPortal2 optimismPortal = IOptimismPortal2(payable(proxies.OptimismPortal));

        // Check that the OptimismPortal implementation is correct.
        require(
            _getImplementation(address(optimismPortal)) == standardVersions.OptimismPortal.implementation,
            "checkOptimismPortal-20"
        );

        // Check that the OptimismPortal is initialized.
        require(vm.load(address(optimismPortal), bytes32(uint256(0))) == bytes32(uint256(1)), "checkOptimismPortal-40");

        // Check that the OptimismPortal refers to the correct DisputeGameFactory.
        require(
            address(optimismPortal.disputeGameFactory()) == address(expectedDisputeGameFactoryProxy),
            "checkOptimismPortal-60"
        );

        // Check that the OptimismPortal refers to the correct SystemConfig.
        require(address(optimismPortal.systemConfig()) == proxies.SystemConfig, "checkOptimismPortal-80");

        // Check that the OptimismPortal refers to the correct SuperchainConfig.
        require(address(optimismPortal.superchainConfig()) == proxies.SuperchainConfig, "checkOptimismPortal-100");

        // Check that the OptimismPortal's initial respected game type is 1 (permissioned).
        require(optimismPortal.respectedGameType().raw() == 1, "checkOptimismPortal-120");

        // Check that the OptimismPortal's l2Sender is the default sender.
        require(optimismPortal.l2Sender() == address(0xdead), "checkOptimismPortal-140");

        // Check that the OptimismPortal's guardian is correct.
        require(optimismPortal.guardian() == expectedGuardian, "checkOptimismPortal-160");
    }

    /// @notice Checks that the SystemConfig was handled correctly.
    function checkSystemConfig() internal {
        // Load contract into correct type.
        ISystemConfig systemConfig = ISystemConfig(proxies.SystemConfig);

        // Check that the SystemConfig implementation is correct.
        require(
            _getImplementation(address(systemConfig)) == standardVersions.SystemConfig.implementation,
            "checkSystemConfig-20"
        );

        // Check that the SystemConfig is initialized.
        require(vm.load(address(systemConfig), bytes32(uint256(0))) == bytes32(uint256(1)), "checkSystemConfig-40");

        // Check that the SystemConfig's DisputeGameFactory reference is correct.
        require(
            address(systemConfig.disputeGameFactory()) == address(expectedDisputeGameFactoryProxy),
            "checkSystemConfig-60"
        );

        // Check that the SystemConfig's L2OutputOracle reference is removed.
        try ISystemConfigLegacy(address(systemConfig)).l2OutputOracle() returns (address) {
            // Function should no longer exist.
            revert("checkSystemConfig-80");
        } catch {
            // Ok.
        }
    }

    /// @notice Checks that the L1CrossDomainMessenger was handled correctly.
    function checkL1CrossDomainMessenger() internal view {
        // Load contract into correct type.
        IL1CrossDomainMessenger l1CrossDomainMessenger = IL1CrossDomainMessenger(proxies.L1CrossDomainMessenger);

        // Check that the L1CrossDomainMessenger implementation is correct.
        require(
            IAddressManager(addressManager).getAddress("OVM_L1CrossDomainMessenger")
                == standardVersions.L1CrossDomainMessenger.implementation,
            "checkL1CrossDomainMessenger-20"
        );

        // Check that the L1CrossDomainMessenger is initialized.
        require(
            vm.load(address(l1CrossDomainMessenger), bytes32(uint256(0)))
                == bytes32(0x0000000000000000000000010000000000000000000000000000000000000000),
            "checkL1CrossDomainMessenger-40"
        );

        // Check that the L1CrossDomainMessenger's SuperchainConfig reference is correct.
        require(
            address(l1CrossDomainMessenger.superchainConfig()) == proxies.SuperchainConfig,
            "checkL1CrossDomainMessenger-60"
        );
    }

    /// @notice Checks that the L1StandardBridge was handled correctly.
    function checkL1StandardBridge() internal {
        // Load contract into correct type.
        IL1StandardBridge l1StandardBridge = IL1StandardBridge(payable(proxies.L1StandardBridge));

        // Check that the L1StandardBridge implementation is correct.
        vm.prank(address(0));
        require(
            IL1ChugSplashProxy(payable(l1StandardBridge)).getImplementation()
                == standardVersions.L1StandardBridge.implementation,
            "checkL1StandardBridge-20"
        );

        // Check that the L1StandardBridge is initialized.
        require(
            vm.load(address(l1StandardBridge), bytes32(uint256(0))) == bytes32(uint256(1)), "checkL1StandardBridge-40"
        );

        // Check that the L1StandardBridge's SuperchainConfig reference is correct.
        require(address(l1StandardBridge.superchainConfig()) == proxies.SuperchainConfig, "checkL1StandardBridge-60");
    }

    /// @notice Checks that the L1ERC721Bridge was handled correctly.
    function checkL1ERC721Bridge() internal {
        // Load contract into correct type.
        IL1ERC721Bridge l1ERC721Bridge = IL1ERC721Bridge(proxies.L1ERC721Bridge);

        // Check that the L1ERC721Bridge implementation is correct.
        require(
            _getImplementation(address(l1ERC721Bridge)) == standardVersions.L1ERC721Bridge.implementation,
            "checkL1ERC721Bridge-20"
        );

        // Check that the L1ERC721Bridge is initialized.
        require(vm.load(address(l1ERC721Bridge), bytes32(uint256(0))) == bytes32(uint256(1)), "checkL1ERC721Bridge-40");
    }

    /// @notice Checks that the OptimismMintableERC20Factory was handled correctly.
    function checkOptimismMintableERC20Factory() internal {
        // Load contract into correct type.
        IOptimismMintableERC20Factory optimismMintableERC20Factory =
            IOptimismMintableERC20Factory(proxies.OptimismMintableERC20Factory);

        // Check that the OptimismMintableERC20Factory implementation is correct.
        require(
            _getImplementation(address(optimismMintableERC20Factory))
                == standardVersions.OptimismMintableERC20Factory.implementation,
            "checkOptimismMintableERC20Factory-20"
        );

        // Check that the OptimismMintableERC20Factory is initialized.
        require(
            vm.load(address(optimismMintableERC20Factory), bytes32(uint256(0))) == bytes32(uint256(1)),
            "checkOptimismMintableERC20Factory-40"
        );
    }

    /// @notice Checks that the AnchorStateRegistry was handled correctly.
    function checkAnchorStateRegistry() internal {
        // Check that the AnchorStateRegistry implementation is correct.
        require(
            _getImplementation(address(expectedAnchorStateRegistryProxy)) == address(expectedAnchorStateRegistryImpl),
            "checkAnchorStateRegistry-20"
        );

        // Check that the AnchorStateRegistry is initialized.
        require(
            vm.load(address(expectedAnchorStateRegistryProxy), bytes32(uint256(0))) == bytes32(uint256(1)),
            "checkAnchorStateRegistry-40"
        );

        // Check that the AnchorStateRegistry's DisputeGameFactory reference is correct.
        require(
            address(expectedAnchorStateRegistryProxy.disputeGameFactory()) == address(expectedDisputeGameFactoryProxy),
            "checkAnchorStateRegistry-60"
        );

        // Check that the AnchorStateRegistry version is correct.
        require(LibString.eq(expectedAnchorStateRegistryProxy.version(), "2.0.0"), "checkAnchorStateRegistry-80");

        // Check that only bytecode diffs vs comparison contract are expected.
        BytecodeComparison.Diff[] memory diffs = new BytecodeComparison.Diff[](3);
        diffs[0] = BytecodeComparison.Diff({start: 387, content: abi.encode(expectedDisputeGameFactoryProxy)});
        diffs[1] = BytecodeComparison.Diff({start: 828, content: abi.encode(expectedDisputeGameFactoryProxy)});
        diffs[2] = BytecodeComparison.Diff({start: 2296, content: abi.encode(expectedDisputeGameFactoryProxy)});
        require(
            BytecodeComparison.compare(
                address(comparisonAnchorStateRegistryImpl), address(expectedAnchorStateRegistryImpl), diffs
            ),
            "checkAnchorStateRegistry-100"
        );

        // Grab the ProxyAdminOwner address from the DisputeGameFactory.
        vm.prank(address(0));
        address proxyAdmin = IProxy(payable(address(expectedDisputeGameFactoryProxy))).admin();
        address proxyAdminOwner = IProxyAdmin(proxyAdmin).owner();

        // Check that the ProxyAdminOwner and DisputeGameFactoryProxyAdminOwner are the same.
        require(proxyAdminOwner == _ownerSafe(), "checkAnchorStateRegistry-120");
    }   

    /// @notice Checks that the DelayedWETH was handled correctly.
    function checkDelayedWETH() internal {
        // Check that the DelayedWETH implementation is correct.
        require(
            _getImplementation(address(expectedDelayedWETHProxy)) == standardVersions.DelayedWETH.implementation,
            "checkDelayedWETH-20"
        );

        // Check that the DelayedWETH is initialized.
        require(
            vm.load(address(expectedDelayedWETHProxy), bytes32(uint256(0))) == bytes32(uint256(1)),
            "checkDelayedWETH-40"
        );

        // Check that the DelayedWETH's owner is correct.
        require(expectedDelayedWETHProxy.owner() == _ownerSafe(), "checkDelayedWETH-40");

        // Check that the DelayedWETH's SuperchainConfig reference is correct.
        require(address(expectedDelayedWETHProxy.config()) == proxies.SuperchainConfig, "checkDelayedWETH-60");

        // Check that the DelayedWETH's ProxyAdminOwner is correct.
        vm.prank(address(0));
        address proxyAdmin = IProxy(payable(expectedDelayedWETHProxy)).admin();
        address proxyAdminOwner = IProxyAdmin(proxyAdmin).owner();

        // Check that the DelayedWETH's ProxyAdminOwner is correct.
        require(proxyAdminOwner == _ownerSafe(), "checkDelayedWETH-80");
    }

    /// @notice Checks that the DisputeGameFactory was handled correctly.
    function checkDisputeGameFactory() internal {
        // Check that the DisputeGameFactory implementation is correct.
        require(
            _getImplementation(address(expectedDisputeGameFactoryProxy))
                == standardVersions.DisputeGameFactory.implementation,
            "checkDisputeGameFactory-20"
        );

        // Check that the DisputeGameFactory is initialized.
        require(
            vm.load(address(expectedDisputeGameFactoryProxy), bytes32(uint256(0))) == bytes32(uint256(1)),
            "checkDisputeGameFactory-40"
        );

        // Check that the DisputeGameFactory's owner is correct.
        require(expectedDisputeGameFactoryProxy.owner() == _ownerSafe(), "checkDisputeGameFactory-60");

        // Check that the DisputeGameFactory's PermissionedDisputeGame implementation is correct.
        require(
            address(expectedDisputeGameFactoryProxy.gameImpls(GameType.wrap(1)))
                == address(expectedPermissionedDisputeGameImpl),
            "checkDisputeGameFactory-80"
        );

        // Check that the DisputeGameFactory has no FaultDisputeGame implementation.
        require(
            address(expectedDisputeGameFactoryProxy.gameImpls(GameType.wrap(0))) == address(0),
            "checkDisputeGameFactory-100"
        );

        // Check that the DisputeGameFactory's ProxyAdminOwner is correct.
        vm.prank(address(0));
        address proxyAdmin = IProxy(payable(address(expectedDisputeGameFactoryProxy))).admin();
        address proxyAdminOwner = IProxyAdmin(proxyAdmin).owner();

        // Check that the DisputeGameFactory's ProxyAdminOwner is correct.
        require(proxyAdminOwner == _ownerSafe(), "checkDisputeGameFactory-120");
    }

    /// @notice Checks that the PermissionedDisputeGame was handled correctly.
    function checkPermissionedDisputeGame() internal view {
        // Check that the PermissionedDisputeGame version is correct.
        require(LibString.eq(expectedPermissionedDisputeGameImpl.version(), "1.3.1"), "checkPermissionedDisputeGame-20");

        // Check that the PermissionedDisputeGame's prestate is correct.
        require(expectedPermissionedDisputeGameImpl.absolutePrestate().raw() == expectedPrestate, "checkPermissionedDisputeGame-40");

        // Check that the PermissionedDisputeGame's Challenger is correct.
        // Should be the same as the reference implementation.
        require(expectedPermissionedDisputeGameImpl.challenger() == comparisonPermissionedDisputeGameImpl.challenger(), "checkPermissionedDisputeGame-60");

        // Check that only bytecode diffs vs comparison contract are expected.
        BytecodeComparison.Diff[] memory diffs = new BytecodeComparison.Diff[](19);
        diffs[0] = BytecodeComparison.Diff({start: 1341, content: abi.encode(expectedDelayedWETHProxy)});
        diffs[1] = BytecodeComparison.Diff({start: 1411, content: abi.encode(chainConfig.challenger)});
        diffs[2] = BytecodeComparison.Diff({start: 1628, content: abi.encode(expectedAnchorStateRegistryProxy)});
        diffs[3] = BytecodeComparison.Diff({start: 1999, content: abi.encode(expectedPrestate)});
        diffs[4] = BytecodeComparison.Diff({start: 2254, content: abi.encode(chainConfig.proposer)});
        diffs[5] = BytecodeComparison.Diff({start: 2714, content: abi.encode(chainConfig.chainId)});
        diffs[6] = BytecodeComparison.Diff({start: 6150, content: abi.encode(expectedAnchorStateRegistryProxy)});
        diffs[7] = BytecodeComparison.Diff({start: 6600, content: abi.encode(expectedDelayedWETHProxy)});
        diffs[8] = BytecodeComparison.Diff({start: 6870, content: abi.encode(chainConfig.proposer)});
        diffs[9] = BytecodeComparison.Diff({start: 6933, content: abi.encode(chainConfig.challenger)});
        diffs[10] = BytecodeComparison.Diff({start: 7076, content: abi.encode(chainConfig.proposer)});
        diffs[11] = BytecodeComparison.Diff({start: 8310, content: abi.encode(chainConfig.proposer)});
        diffs[12] = BytecodeComparison.Diff({start: 8373, content: abi.encode(chainConfig.challenger)});
        diffs[13] = BytecodeComparison.Diff({start: 9555, content: abi.encode(chainConfig.chainId)});
        diffs[14] = BytecodeComparison.Diff({start: 10798, content: abi.encode(expectedDelayedWETHProxy)});
        diffs[15] = BytecodeComparison.Diff({start: 13599, content: abi.encode(expectedDelayedWETHProxy)});
        diffs[16] = BytecodeComparison.Diff({start: 13946, content: abi.encode(expectedAnchorStateRegistryProxy)});
        diffs[17] = BytecodeComparison.Diff({start: 14972, content: abi.encode(expectedDelayedWETHProxy)});
        diffs[18] = BytecodeComparison.Diff({start: 17022, content: abi.encode(expectedPrestate)});
        require(
            BytecodeComparison.compare(
                address(comparisonPermissionedDisputeGameImpl), address(expectedPermissionedDisputeGameImpl), diffs
            ),
            "checkPermissionedDisputeGame-80"
        );
    }

    /// @notice Returns the implementation of a proxy.
    /// @param _proxy The proxy to get the implementation of.
    /// @return implementation_ The implementation of the proxy.
    function _getImplementation(address _proxy) internal returns (address implementation_) {
        vm.prank(address(0));
        implementation_ = IProxy(payable(_proxy)).implementation();
    }
}
