// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Signatures} from "@base-contracts/script/universal/Signatures.sol";

import {RevenueShareV100UpgradePath} from "src/template/RevenueShareUpgradePath.sol";
import {SimpleAddressRegistry} from "src/SimpleAddressRegistry.sol";
import {Action, TaskPayload, SafeData} from "src/libraries/MultisigTypes.sol";
import {Utils} from "src/libraries/Utils.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface ICreate2Deployer {
    function deploy(uint256 _value, bytes32 _salt, bytes memory _code) external;
}

interface IProxyAdmin {
    function upgrade(address _proxy, address _implementation) external;
    function upgradeAndCall(address _proxy, address _implementation, bytes memory _data) external payable returns (bytes memory);
}

contract RevenueShareUpgradePathTest is Test {
    using stdStorage for StdStorage;

    event TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData);

    RevenueShareV100UpgradePath public template;

    // Expected addresses from config
    address public constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address public constant PROXY_ADMIN_OWNER = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;

    // Expected number of actions
    uint256 public constant EXPECTED_DEPLOYMENTS_OPT_IN = 7;
    uint256 public constant EXPECTED_UPGRADES_OPT_IN = 5;
    uint256 public constant EXPECTED_DEPLOYMENTS_OPT_OUT = 5;
    uint256 public constant EXPECTED_UPGRADES_OPT_OUT = 5;

    // L2 predeploys
    address internal constant CREATE2_DEPLOYER = 0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2;
    address internal constant FEE_SPLITTER = 0x420000000000000000000000000000000000002B;
    address internal constant PROXY_ADMIN = 0x4200000000000000000000000000000000000018;

    // Gas limits, defined in the template based on the transaction simulations
    uint64 internal constant SC_REV_SHARE_CALCULATOR_DEPLOYMENT_GAS_LIMIT = 625_000;
    uint64 internal constant L1_WITHDRAWER_DEPLOYMENT_GAS_LIMIT = 625_000;
    uint64 internal constant FEE_VAULTS_DEPLOYMENT_GAS_LIMIT = 910_000;
    uint64 internal constant FEE_SPLITTER_DEPLOYMENT_GAS_LIMIT = 1_235_000;
    uint64 internal constant UPGRADE_GAS_LIMIT = 150_000;

    uint64[12] internal EXPECTED_GAS_LIMITS_OPT_IN = [
        L1_WITHDRAWER_DEPLOYMENT_GAS_LIMIT,
        SC_REV_SHARE_CALCULATOR_DEPLOYMENT_GAS_LIMIT,
        FEE_SPLITTER_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT,
        FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT,
        FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT,
        FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT,
        FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT
    ];

    uint64[10] internal EXPECTED_GAS_LIMITS_OPT_OUT = [
        FEE_SPLITTER_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT,
        FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT,
        FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT,
        FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT,
        FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
        UPGRADE_GAS_LIMIT
    ];

    uint256 internal constant DEPOSIT_VERSION = 0;

    function _mockAndExpect(address _receiver, bytes memory _calldata, bytes memory _returned) internal {
        vm.mockCall(_receiver, _calldata, _returned);
        vm.expectCall(_receiver, _calldata);
    }

    function setUp() public {
        vm.createSelectFork("mainnet");

        template = new RevenueShareV100UpgradePath();
    }

    function test_optInRevenueShare_succeeds() public {
        _testRevenueShareUpgrade(
            "test/tasks/example/eth/015-revenue-share-upgrade/config.toml",
            true, // isOptIn
            EXPECTED_DEPLOYMENTS_OPT_IN + EXPECTED_UPGRADES_OPT_IN,
            EXPECTED_DEPLOYMENTS_OPT_IN,
            EXPECTED_UPGRADES_OPT_IN,
            "Should have 12 actions for opt-in scenario"
        );
    }

    function test_optOutRevenueShare_succeeds() public {
        _testRevenueShareUpgrade(
            "test/tasks/example/eth/019-revenueshare-upgrade-opt-out/config.toml",
            false, // isOptIn
            EXPECTED_DEPLOYMENTS_OPT_OUT + EXPECTED_UPGRADES_OPT_OUT,
            EXPECTED_DEPLOYMENTS_OPT_OUT,
            EXPECTED_UPGRADES_OPT_OUT,
            "Should have 10 actions for non-opt-in scenario"
        );
    }

    /// @notice Helper function to test revenue share upgrade scenarios
    /// @param _configPath Path to the config file
    /// @param _isOptIn Whether this is an opt-in or opt-out scenario
    /// @param _expectedTotalActions Expected total number of actions
    /// @param _expectedDeployments Expected number of deployment actions
    /// @param _expectedUpgrades Expected number of upgrade actions
    /// @param _actionCountMessage Assertion message for action count verification
    function _testRevenueShareUpgrade(
        string memory _configPath,
        bool _isOptIn,
        uint256 _expectedTotalActions,
        uint256 _expectedDeployments,
        uint256 _expectedUpgrades,
        string memory _actionCountMessage
    ) internal {
        // Step 1: Run simulate to prepare everything and get the actions
        (, Action[] memory _actions,,, address _rootSafe) = template.simulate(_configPath, new address[](0));

        // Verify we got the expected safe and action count
        assertEq(_rootSafe, PROXY_ADMIN_OWNER, "Root safe should be ProxyAdminOwner");
        assertEq(_actions.length, _expectedTotalActions, _actionCountMessage);

        // Step 2: Get the safe's owners
        IGnosisSafe _safe = IGnosisSafe(_rootSafe);
        address[] memory _owners = _safe.getOwners();

        // Step 3: Get the multicall calldata that will be executed
        IMulticall3.Call3Value[] memory _calls = new IMulticall3.Call3Value[](_actions.length);
        for (uint256 i; i < _actions.length; i++) {
            _calls[i] = IMulticall3.Call3Value({
                target: _actions[i].target,
                allowFailure: false,
                value: _actions[i].value,
                callData: _actions[i].arguments
            });
        }
        bytes memory _multicallData = abi.encodeCall(IMulticall3.aggregate3Value, (_calls));

        // Step 4: Get the nonce and compute transaction hash before any state changes
        uint256 _nonceBefore = _safe.nonce();

        bytes32 _txHash = _safe.getTransactionHash(
            template.multicallTarget(),
            0, // value
            _multicallData,
            Enum.Operation.DelegateCall,
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            _nonceBefore
        );

        // Step 5: Manually verify expected portal calls based on known config values
        _verifyExpectedPortalCalls(_actions, _isOptIn);

        // Step 6: Prank owners to approve the transaction
        for (uint256 i; i < _owners.length; i++) {
            vm.prank(_owners[i]);
            _safe.approveHash(_txHash);
        }

        // Step 7: Generate signatures after approval
        bytes memory _signatures = Signatures.genPrevalidatedSignatures(_owners);

        _expectPortalEvents(_actions);

        // Step 8: Execute the transaction
        bool _success = _safe.execTransaction(
            template.multicallTarget(),
            0, // value
            _multicallData,
            Enum.Operation.DelegateCall,
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            _signatures
        );

        assertTrue(_success, "Transaction should execute successfully");
        assertEq(_safe.nonce(), _nonceBefore + 1, "Safe nonce should increment");

        // Step 9: Verify the portal calls
        _verifyPortalCalls(_actions, _expectedDeployments, _expectedUpgrades);
    }

    /// @notice Verify the portal calls based on the expected deployments and upgrades
    /// @param _actions The actions to verify
    /// @param _expectedDeployments The expected number of deployments
    /// @param _expectedUpgrades The expected number of upgrades
    function _verifyPortalCalls(Action[] memory _actions, uint256 _expectedDeployments, uint256 _expectedUpgrades)
        internal
        pure
    {
        uint256 _deploymentCalls = 0;
        uint256 _upgradeCalls = 0;

        for (uint256 i; i < _actions.length; i++) {
            // Decode the depositTransaction parameters
            bytes memory _params = new bytes(_actions[i].arguments.length - 4);
            for (uint256 j; j < _params.length; j++) {
                _params[j] = _actions[i].arguments[j + 4];
            }
            (address _to,,,,) = abi.decode(_params, (address, uint256, uint64, bool, bytes));

            if (_to == CREATE2_DEPLOYER) {
                _deploymentCalls++;
            } else {
                _upgradeCalls++;
            }
        }

        assertEq(_deploymentCalls, _expectedDeployments, "Incorrect number of deployment calls");
        assertEq(_upgradeCalls, _expectedUpgrades, "Incorrect number of upgrade calls");
    }

    /// @notice Manually construct and expect portal calls based on known config values
    /// This ensures the template generates correct calldata, not just circular validation
    function _verifyExpectedPortalCalls(Action[] memory _actions, bool _isOptIn) internal {
        uint256 _deploymentCount;
        uint256 _upgradeCount;

        for (uint256 i; i < _actions.length; i++) {
            bytes memory _params = _extractParams(_actions[i].arguments);
            // depending on if is optin or optout, we use the expected gas limits
            uint64 _gasLimit = _isOptIn ? EXPECTED_GAS_LIMITS_OPT_IN[i] : EXPECTED_GAS_LIMITS_OPT_OUT[i];
            (address _to, uint256 _value, uint64 _actualGasLimit, bool _isCreation, bytes memory _data) =
                abi.decode(_params, (address, uint256, uint64, bool, bytes));

            assertEq(_actions[i].target, PORTAL, "All actions should target the portal");
            _verifyCommonParams(_value, _actualGasLimit, _gasLimit, _isCreation, _data);

            if (_to == CREATE2_DEPLOYER) {
                _deploymentCount++;
                _verifyDeploymentCall(_gasLimit, _data);
            } else {
                _upgradeCount++;
                _verifyUpgradeCall(_to, _gasLimit, _data);
            }
        }

        assertGt(_deploymentCount, 0, "Should have at least one deployment");
        assertGt(_upgradeCount, 0, "Should have at least one upgrade");
        assertEq(_deploymentCount + _upgradeCount, _actions.length, "All actions should be accounted for");
    }

    /// @notice Extract the parameters from the arguments
    /// @param _arguments The arguments to extract the parameters from
    /// @return The parameters
    function _extractParams(bytes memory _arguments) internal pure returns (bytes memory) {
        bytes memory _params = new bytes(_arguments.length - 4);
        for (uint256 j; j < _params.length; j++) {
            _params[j] = _arguments[j + 4];
        }
        return _params;
    }

    /// @notice Verify the parameters on the expected portal calls
    /// @param _value The value
    /// @param _actualGasLimit The actual gas limit
    /// @param _expectedGasLimit The expected gas limit
    /// @param _isCreation The is creation
    /// @param _data The data, only checking calldata length
    /// it is better tested in RevenueShareUpgradePath.sol::_validate
    function _verifyCommonParams(
        uint256 _value,
        uint64 _actualGasLimit,
        uint64 _expectedGasLimit,
        bool _isCreation,
        bytes memory _data
    ) internal pure {
        require(_value == 0, "All calls should have 0 value");
        require(_actualGasLimit == _expectedGasLimit, "Gas limit should match config");
        require(!_isCreation, "Should not use creation flag");
        require(_data.length > 0, "Should have calldata");
    }

    /// @notice Verify the deployment call
    /// @param _gasLimit The expected gas limit
    /// @param _data The expected data
    function _verifyDeploymentCall(uint64 _gasLimit, bytes memory _data) internal {
        vm.expectCall(
            PORTAL, abi.encodeCall(IOptimismPortal2.depositTransaction, (CREATE2_DEPLOYER, 0, _gasLimit, false, _data))
        );

        bytes4 _actualSelector;
        assembly {
            _actualSelector := mload(add(_data, 32))
        }
        assertEq(_actualSelector, ICreate2Deployer.deploy.selector, "Deployment should call CREATE2 deploy");
    }

    /// @notice Verify the upgrade call
    /// @param _to The target address, it MUST be the proxy admin
    /// @param _gasLimit The expected gas limit
    /// @param _data The expected data
    function _verifyUpgradeCall(address _to, uint64 _gasLimit, bytes memory _data) internal {
        vm.expectCall(PORTAL, abi.encodeCall(IOptimismPortal2.depositTransaction, (_to, 0, _gasLimit, false, _data)));

        _assertIsProxyAdmin(_to);

        bytes4 _selector;
        assembly {
            _selector := mload(add(_data, 32))
        }
        assertTrue(
            _selector == IProxyAdmin.upgrade.selector || _selector == IProxyAdmin.upgradeAndCall.selector,
            "Upgrade should call upgradeTo or upgradeToAndCall"
        );
    }

    /// @notice Verify the target address is the proxy admin
    /// @param _to The target address
    function _assertIsProxyAdmin(address _to) internal pure {
        assertTrue(
            _to == PROXY_ADMIN,
            "Upgrade should target the proxy admin"
        );
    }

    /// @notice Expect the portal events
    /// @param _actions The actions to expect the events for
    function _expectPortalEvents(Action[] memory _actions) internal {
        for (uint256 i; i < _actions.length; i++) {
            bytes memory _params = _extractParams(_actions[i].arguments);
            (address _to,, uint64 _actualGasLimit, bool _isCreation, bytes memory _data) =
                abi.decode(_params, (address, uint256, uint64, bool, bytes));

            bytes memory _opaqueData = abi.encodePacked(uint256(0), uint256(0), _actualGasLimit, _isCreation, _data);

            vm.expectEmit(true, true, true, true, PORTAL);
            emit TransactionDeposited(AddressAliasHelper.applyL1ToL2Alias(PROXY_ADMIN_OWNER), _to, DEPOSIT_VERSION, _opaqueData);
        }
    }
}
