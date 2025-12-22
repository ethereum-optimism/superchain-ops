// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// Testing
import {Test} from "forge-std/Test.sol";

// Contract under test
import {RevShareContractsUpgrader} from "src/RevShareContractsUpgrader.sol";

// Libraries
import {FeeVaultUpgrader} from "src/libraries/FeeVaultUpgrader.sol";
import {FeeSplitterSetup} from "src/libraries/FeeSplitterSetup.sol";
import {Utils} from "src/libraries/Utils.sol";
import {RevShareCommon} from "src/libraries/RevShareCommon.sol";

// Interfaces
import {IOptimismPortal2} from "@eth-optimism-bedrock/interfaces/L1/IOptimismPortal2.sol";
import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {ICreate2Deployer} from "src/interfaces/ICreate2Deployer.sol";
import {IFeeSplitter} from "src/interfaces/IFeeSplitter.sol";
import {IFeeVault} from "src/interfaces/IFeeVault.sol";

/// @title RevShareContractsUpgrader_TestInit
/// @notice Base test contract with shared setup and helpers for RevShareContractsUpgrader tests.
contract RevShareContractsUpgrader_TestInit is Test {
    // Events
    event ChainProcessed(address portal, uint256 chainIndex);

    // Contract under test
    RevShareContractsUpgrader internal upgrader;

    // Test constants
    address internal immutable PORTAL_ONE = makeAddr("PORTAL_ONE");
    address internal immutable PORTAL_TWO = makeAddr("PORTAL_TWO");
    address internal immutable L1_RECIPIENT_ONE = makeAddr("L1_RECIPIENT_ONE");
    address internal immutable L1_RECIPIENT_TWO = makeAddr("L1_RECIPIENT_TWO");
    address internal immutable CHAIN_FEES_RECIPIENT_ONE = makeAddr("CHAIN_FEES_RECIPIENT_ONE");
    address internal immutable CHAIN_FEES_RECIPIENT_TWO = makeAddr("CHAIN_FEES_RECIPIENT_TWO");
    uint256 internal immutable MIN_WITHDRAWAL_AMOUNT = 1 ether;
    uint32 internal immutable GAS_LIMIT = 500_000;

    /// @notice Test setup
    function setUp() public {
        upgrader = new RevShareContractsUpgrader();
    }

    function _assumeValidAddress(address _address) internal pure {
        assumeNotZeroAddress(_address);
        assumeNotForgeAddress(_address);
        assumeNotPrecompile(_address);
    }

    /// @notice Helper function to setup a mock and expect a call to it.
    function _mockAndExpect(address _receiver, bytes memory _calldata, bytes memory _returned) internal {
        vm.mockCall(_receiver, _calldata, _returned);
        vm.expectCall(_receiver, _calldata);
    }

    /// @notice Helper to create RevShareConfig
    function _createRevShareConfig(
        address _portal,
        uint256 _minWithdrawalAmount,
        address _l1Recipient,
        uint32 _gasLimit,
        address _chainFeesRecipient
    ) internal pure returns (RevShareContractsUpgrader.RevShareConfig memory) {
        return RevShareContractsUpgrader.RevShareConfig({
            portal: _portal,
            l1WithdrawerConfig: FeeSplitterSetup.L1WithdrawerConfig({
                minWithdrawalAmount: _minWithdrawalAmount,
                recipient: _l1Recipient,
                gasLimit: _gasLimit
            }),
            chainFeesRecipient: _chainFeesRecipient
        });
    }

    /// @notice Helper to calculate expected CREATE2 address
    function _calculateExpectedCreate2Address(string memory _suffix, bytes memory _initCode)
        internal
        pure
        returns (address _expectedAddress)
    {
        bytes32 salt = keccak256(abi.encodePacked("RevShare", ":", _suffix));
        _expectedAddress = Utils.getCreate2Address(salt, _initCode, RevShareCommon.CREATE2_DEPLOYER);
        assumeNotZeroAddress(_expectedAddress);
    }

    /// @notice Helper to mock L1Withdrawer deployment
    function _mockAndExpectL1WithdrawerDeploy(
        address _portal,
        uint256 _minWithdrawalAmount,
        address _recipient,
        uint32 _gasLimit
    ) internal {
        bytes memory l1WithdrawerInitCode = bytes.concat(
            FeeSplitterSetup.l1WithdrawerCreationCode, abi.encode(_minWithdrawalAmount, _recipient, _gasLimit)
        );
        bytes32 salt = keccak256(abi.encodePacked("RevShare", ":", "L1Withdrawer"));

        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    RevShareCommon.CREATE2_DEPLOYER,
                    0,
                    FeeSplitterSetup.L1_WITHDRAWER_DEPLOYMENT_GAS_LIMIT,
                    false,
                    abi.encodeCall(ICreate2Deployer.deploy, (0, salt, l1WithdrawerInitCode))
                )
            ),
            abi.encode()
        );
    }

    /// @notice Helper to mock Calculator deployment
    function _mockAndExpectCalculatorDeploy(address _portal, address _l1Withdrawer, address _chainFeesRecipient)
        internal
    {
        bytes memory calculatorInitCode = bytes.concat(
            FeeSplitterSetup.scRevShareCalculatorCreationCode, abi.encode(_l1Withdrawer, _chainFeesRecipient)
        );
        bytes32 salt = keccak256(abi.encodePacked("RevShare", ":", "SCRevShareCalculator"));

        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    RevShareCommon.CREATE2_DEPLOYER,
                    0,
                    FeeSplitterSetup.SC_REV_SHARE_CALCULATOR_DEPLOYMENT_GAS_LIMIT,
                    false,
                    abi.encodeCall(ICreate2Deployer.deploy, (0, salt, calculatorInitCode))
                )
            ),
            abi.encode()
        );
    }

    /// @notice Helper to mock FeeSplitter deployment
    function _mockAndExpectFeeSplitterDeployAndSetup(address _portal, address _calculator) internal {
        // FeeSplitter deployment deposit
        bytes32 salt = keccak256(abi.encodePacked("RevShare", ":", "FeeSplitter"));
        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    RevShareCommon.CREATE2_DEPLOYER,
                    0,
                    FeeSplitterSetup.FEE_SPLITTER_DEPLOYMENT_GAS_LIMIT,
                    false,
                    abi.encodeCall(ICreate2Deployer.deploy, (0, salt, FeeSplitterSetup.feeSplitterCreationCode))
                )
            ),
            abi.encode()
        );

        // Initialize FeeSplitter with calculator deposit
        address feeSplitterImpl =
            _calculateExpectedCreate2Address("FeeSplitter", FeeSplitterSetup.feeSplitterCreationCode);

        bytes memory upgradeCall = abi.encodeCall(
            IProxyAdmin.upgradeAndCall,
            (
                payable(RevShareCommon.FEE_SPLITTER),
                feeSplitterImpl,
                abi.encodeCall(IFeeSplitter.initialize, (_calculator))
            )
        );

        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (RevShareCommon.PROXY_ADMIN, 0, RevShareCommon.UPGRADE_GAS_LIMIT, false, upgradeCall)
            ),
            abi.encode()
        );
    }

    /// @notice Helper to mock FeeSplitter setSharesCalculator call
    function _mockAndExpectFeeSplitterSetCalculator(address _portal, address _calculator) internal {
        bytes memory setCalculatorCall = abi.encodeCall(IFeeSplitter.setSharesCalculator, (_calculator));

        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (RevShareCommon.FEE_SPLITTER, 0, RevShareCommon.SETTERS_GAS_LIMIT, false, setCalculatorCall)
            ),
            abi.encode()
        );
    }

    /// @notice Helper to mock a single vault deployment and upgrade
    function _mockAndExpectVaultUpgrade(
        address _portal,
        address _vault,
        string memory _vaultName,
        bytes memory _creationCode
    ) internal {
        // Mock vault implementation deployment
        bytes32 salt = keccak256(abi.encodePacked("RevShare", ":", _vaultName));
        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    RevShareCommon.CREATE2_DEPLOYER,
                    0,
                    FeeVaultUpgrader.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
                    false,
                    abi.encodeCall(ICreate2Deployer.deploy, (0, salt, _creationCode))
                )
            ),
            abi.encode()
        );

        // Mock vault upgrade call
        address vaultImpl = _calculateExpectedCreate2Address(_vaultName, _creationCode);
        bytes memory vaultUpgradeCall = abi.encodeCall(
            IProxyAdmin.upgradeAndCall,
            (
                payable(_vault),
                vaultImpl,
                abi.encodeCall(IFeeVault.initialize, (RevShareCommon.FEE_SPLITTER, 0, IFeeVault.WithdrawalNetwork.L2))
            )
        );

        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (RevShareCommon.PROXY_ADMIN, 0, RevShareCommon.UPGRADE_GAS_LIMIT, false, vaultUpgradeCall)
            ),
            abi.encode()
        );
    }

    /// @notice Helper to mock a single vault setter calls
    function _mockAndExpectVaultSetter(address _portal, address _vault) internal {
        // Mock setRecipient call
        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    _vault,
                    0,
                    RevShareCommon.SETTERS_GAS_LIMIT,
                    false,
                    abi.encodeCall(IFeeVault.setRecipient, (RevShareCommon.FEE_SPLITTER))
                )
            ),
            abi.encode()
        );

        // Mock setMinWithdrawalAmount call
        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    _vault,
                    0,
                    RevShareCommon.SETTERS_GAS_LIMIT,
                    false,
                    abi.encodeCall(IFeeVault.setMinWithdrawalAmount, (0))
                )
            ),
            abi.encode()
        );

        // Mock setWithdrawalNetwork call
        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    _vault,
                    0,
                    RevShareCommon.SETTERS_GAS_LIMIT,
                    false,
                    abi.encodeCall(IFeeVault.setWithdrawalNetwork, (IFeeVault.WithdrawalNetwork.L2))
                )
            ),
            abi.encode()
        );
    }

    /// @notice Helper to mock only a vault upgrade (no deployment) - for vaults that reuse another vault's implementation
    /// @param _portal The portal address
    /// @param _vault The vault proxy address to upgrade
    /// @param _implVaultName The vault name whose implementation to reuse (e.g., "BaseFeeVault" for L1FeeVault)
    /// @param _creationCode The creation code of the implementation being reused
    function _mockAndExpectVaultUpgradeOnly(
        address _portal,
        address _vault,
        string memory _implVaultName,
        bytes memory _creationCode
    ) internal {
        // Calculate the implementation address (using the name of the vault whose impl we're reusing)
        address vaultImpl = _calculateExpectedCreate2Address(_implVaultName, _creationCode);

        // Mock vault upgrade call (no deployment, just upgrade)
        bytes memory vaultUpgradeCall = abi.encodeCall(
            IProxyAdmin.upgradeAndCall,
            (
                payable(_vault),
                vaultImpl,
                abi.encodeCall(IFeeVault.initialize, (RevShareCommon.FEE_SPLITTER, 0, IFeeVault.WithdrawalNetwork.L2))
            )
        );

        _mockAndExpect(
            _portal,
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (RevShareCommon.PROXY_ADMIN, 0, RevShareCommon.UPGRADE_GAS_LIMIT, false, vaultUpgradeCall)
            ),
            abi.encode()
        );
    }

    /// @notice Helper to mock all vault upgrades (3 vault deployments + 4 upgrades)
    /// @dev BaseFeeVault and L1FeeVault share the same implementation, so only BaseFeeVault is deployed
    function _mockAndExpectAllVaultUpgrades(address _portal) internal {
        // Deploy and upgrade OperatorFeeVault
        _mockAndExpectVaultUpgrade(
            _portal,
            FeeVaultUpgrader.OPERATOR_FEE_VAULT,
            "OperatorFeeVault",
            FeeVaultUpgrader.operatorFeeVaultCreationCode
        );

        // Deploy and upgrade SequencerFeeVault
        _mockAndExpectVaultUpgrade(
            _portal,
            FeeVaultUpgrader.SEQUENCER_FEE_WALLET,
            "SequencerFeeVault",
            FeeVaultUpgrader.sequencerFeeVaultCreationCode
        );

        // Deploy and upgrade BaseFeeVault (this deployment is shared with L1FeeVault)
        _mockAndExpectVaultUpgrade(
            _portal, FeeVaultUpgrader.BASE_FEE_VAULT, "BaseFeeVault", FeeVaultUpgrader.defaultFeeVaultCreationCode
        );

        // L1FeeVault upgrade only (reuses BaseFeeVault's implementation, no deployment)
        _mockAndExpectVaultUpgradeOnly(
            _portal, FeeVaultUpgrader.L1_FEE_VAULT, "BaseFeeVault", FeeVaultUpgrader.defaultFeeVaultCreationCode
        );
    }

    /// @notice Helper to mock all vault setters (4 vaults, 3 calls each = 12 calls total)
    function _mockAndExpectAllVaultSetters(address _portal) internal {
        _mockAndExpectVaultSetter(_portal, FeeVaultUpgrader.OPERATOR_FEE_VAULT);
        _mockAndExpectVaultSetter(_portal, FeeVaultUpgrader.SEQUENCER_FEE_WALLET);
        _mockAndExpectVaultSetter(_portal, FeeVaultUpgrader.BASE_FEE_VAULT);
        _mockAndExpectVaultSetter(_portal, FeeVaultUpgrader.L1_FEE_VAULT);
    }
}

/// @title RevShareContractsUpgrader_UpgradeAndSetupRevShare_Test
/// @notice Tests for the upgradeAndSetupRevShare function of the RevShareContractsUpgrader contract.
contract RevShareContractsUpgrader_UpgradeAndSetupRevShare_Test is RevShareContractsUpgrader_TestInit {
    /// @notice Test that upgradeAndSetupRevShare reverts when configs array is empty
    function test_upgradeAndSetupRevShare_whenEmptyArray_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](0);

        vm.expectRevert(RevShareContractsUpgrader.EmptyArray.selector);
        upgrader.upgradeAndSetupRevShare(configs);
    }

    /// @notice Test that upgradeAndSetupRevShare reverts when portal address is zero
    function test_upgradeAndSetupRevShare_whenPortalIsZero_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] = _createRevShareConfig(
            address(0), MIN_WITHDRAWAL_AMOUNT, L1_RECIPIENT_ONE, GAS_LIMIT, CHAIN_FEES_RECIPIENT_ONE
        );

        vm.expectRevert(RevShareContractsUpgrader.PortalCannotBeZeroAddress.selector);
        upgrader.upgradeAndSetupRevShare(configs);
    }

    /// @notice Test that upgradeAndSetupRevShare reverts when L1Withdrawer recipient is zero
    function test_upgradeAndSetupRevShare_whenL1WithdrawerRecipientIsZero_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] =
            _createRevShareConfig(PORTAL_ONE, MIN_WITHDRAWAL_AMOUNT, address(0), GAS_LIMIT, CHAIN_FEES_RECIPIENT_ONE);

        vm.expectRevert(RevShareContractsUpgrader.L1WithdrawerRecipientCannotBeZeroAddress.selector);
        upgrader.upgradeAndSetupRevShare(configs);
    }

    /// @notice Test that upgradeAndSetupRevShare reverts when chain fees recipient is zero
    function test_upgradeAndSetupRevShare_whenChainFeesRecipientIsZero_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] = _createRevShareConfig(PORTAL_ONE, MIN_WITHDRAWAL_AMOUNT, L1_RECIPIENT_ONE, GAS_LIMIT, address(0));

        vm.expectRevert(RevShareContractsUpgrader.ChainFeesRecipientCannotBeZeroAddress.selector);
        upgrader.upgradeAndSetupRevShare(configs);
    }

    /// @notice Test that upgradeAndSetupRevShare reverts when gas limit is zero
    function test_upgradeAndSetupRevShare_whenGasLimitIsZero_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] =
            _createRevShareConfig(PORTAL_ONE, MIN_WITHDRAWAL_AMOUNT, L1_RECIPIENT_ONE, 0, CHAIN_FEES_RECIPIENT_ONE);

        vm.expectRevert(RevShareContractsUpgrader.GasLimitCannotBeZero.selector);
        upgrader.upgradeAndSetupRevShare(configs);
    }

    /// @notice Fuzz test successful upgradeAndSetupRevShare with single chain
    function testFuzz_upgradeAndSetupRevShare_singleChain_succeeds(
        address _portal,
        uint256 _minWithdrawalAmount,
        address _l1Recipient,
        uint32 _gasLimit,
        address _chainFeesRecipient
    ) public {
        // Bound inputs to valid ranges
        _assumeValidAddress(_portal);
        _assumeValidAddress(_l1Recipient);
        _assumeValidAddress(_chainFeesRecipient);
        _gasLimit = uint32(bound(_gasLimit, 1, type(uint32).max));

        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] = _createRevShareConfig(_portal, _minWithdrawalAmount, _l1Recipient, _gasLimit, _chainFeesRecipient);

        // Calculate expected L1Withdrawer address
        bytes memory l1WithdrawerInitCode = bytes.concat(
            FeeSplitterSetup.l1WithdrawerCreationCode, abi.encode(_minWithdrawalAmount, _l1Recipient, _gasLimit)
        );
        address expectedL1Withdrawer = _calculateExpectedCreate2Address("L1Withdrawer", l1WithdrawerInitCode);

        // Calculate expected Calculator address
        bytes memory calculatorInitCode = bytes.concat(
            FeeSplitterSetup.scRevShareCalculatorCreationCode, abi.encode(expectedL1Withdrawer, _chainFeesRecipient)
        );
        address expectedCalculator = _calculateExpectedCreate2Address("SCRevShareCalculator", calculatorInitCode);

        // Mock all calls with strict abi.encodeCall
        _mockAndExpectL1WithdrawerDeploy(_portal, _minWithdrawalAmount, _l1Recipient, _gasLimit);
        _mockAndExpectCalculatorDeploy(_portal, expectedL1Withdrawer, _chainFeesRecipient);
        _mockAndExpectFeeSplitterDeployAndSetup(_portal, expectedCalculator);
        _mockAndExpectAllVaultUpgrades(_portal);

        // Expect event
        vm.expectEmit(address(upgrader));
        emit ChainProcessed(_portal, 0);

        // Execute
        upgrader.upgradeAndSetupRevShare(configs);
    }

    /// @notice Fuzz test successful upgradeAndSetupRevShare with multiple chains
    function testFuzz_upgradeAndSetupRevShare_multipleChains_succeeds(uint8 _numChains, uint256 _seed) public {
        // Bound to reasonable range: 2-50 chains
        _numChains = uint8(bound(_numChains, 2, 50));

        // Setup configs array
        RevShareContractsUpgrader.RevShareConfig[] memory configs =
            new RevShareContractsUpgrader.RevShareConfig[](_numChains);

        // Generate random configs and setup mocks for each chain
        for (uint256 i; i < _numChains; ++i) {
            // Use seed + index to generate pseudo-random but deterministic values
            uint256 chainSeed = uint256(keccak256(abi.encode(_seed, i)));

            // Generate random but valid addresses (non-zero)
            address portal = makeAddr(string.concat("portal_", vm.toString(chainSeed)));
            address l1Recipient = makeAddr(string.concat("l1recipient_", vm.toString(chainSeed)));
            address chainFeeRecipient = makeAddr(string.concat("chainfee_", vm.toString(chainSeed)));

            // Generate random config values
            uint256 minWithdrawalAmount =
                bound(uint256(keccak256(abi.encode(chainSeed, "minwithdrawal"))), 1, type(uint256).max);
            uint32 gasLimit = uint32(bound(uint256(keccak256(abi.encode(chainSeed, "gaslimit"))), 1, type(uint32).max));

            configs[i] = _createRevShareConfig(portal, minWithdrawalAmount, l1Recipient, gasLimit, chainFeeRecipient);

            // Calculate expected addresses for this chain
            bytes memory l1WithdrawerInitCode = bytes.concat(
                FeeSplitterSetup.l1WithdrawerCreationCode, abi.encode(minWithdrawalAmount, l1Recipient, gasLimit)
            );
            address expectedL1Withdrawer = _calculateExpectedCreate2Address("L1Withdrawer", l1WithdrawerInitCode);

            bytes memory calculatorInitCode = bytes.concat(
                FeeSplitterSetup.scRevShareCalculatorCreationCode, abi.encode(expectedL1Withdrawer, chainFeeRecipient)
            );
            address expectedCalculator = _calculateExpectedCreate2Address("SCRevShareCalculator", calculatorInitCode);

            // Setup mocks for this chain
            _mockAndExpectL1WithdrawerDeploy(portal, minWithdrawalAmount, l1Recipient, gasLimit);
            _mockAndExpectCalculatorDeploy(portal, expectedL1Withdrawer, chainFeeRecipient);
            _mockAndExpectFeeSplitterDeployAndSetup(portal, expectedCalculator);
            _mockAndExpectAllVaultUpgrades(portal);

            // Expect event for this chain
            vm.expectEmit(address(upgrader));
            emit ChainProcessed(portal, i);
        }

        // Execute once with all chains
        upgrader.upgradeAndSetupRevShare(configs);
    }
}

/// @title RevShareContractsUpgrader_SetupRevShare_Test
/// @notice Tests for the setupRevShare function of the RevShareContractsUpgrader contract.
contract RevShareContractsUpgrader_SetupRevShare_Test is RevShareContractsUpgrader_TestInit {
    /// @notice Test that setupRevShare reverts when configs array is empty
    function test_setupRevShare_whenEmptyArray_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](0);

        vm.expectRevert(RevShareContractsUpgrader.EmptyArray.selector);
        upgrader.setupRevShare(configs);
    }

    /// @notice Test that setupRevShare reverts when portal address is zero
    function test_setupRevShare_whenPortalIsZero_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] = _createRevShareConfig(
            address(0), MIN_WITHDRAWAL_AMOUNT, L1_RECIPIENT_ONE, GAS_LIMIT, CHAIN_FEES_RECIPIENT_ONE
        );

        vm.expectRevert(RevShareContractsUpgrader.PortalCannotBeZeroAddress.selector);
        upgrader.setupRevShare(configs);
    }

    /// @notice Test that setupRevShare reverts when L1Withdrawer recipient is zero
    function test_setupRevShare_whenL1WithdrawerRecipientIsZero_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] =
            _createRevShareConfig(PORTAL_ONE, MIN_WITHDRAWAL_AMOUNT, address(0), GAS_LIMIT, CHAIN_FEES_RECIPIENT_ONE);

        vm.expectRevert(RevShareContractsUpgrader.L1WithdrawerRecipientCannotBeZeroAddress.selector);
        upgrader.setupRevShare(configs);
    }

    /// @notice Test that setupRevShare reverts when chain fees recipient is zero
    function test_setupRevShare_whenChainFeesRecipientIsZero_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] = _createRevShareConfig(PORTAL_ONE, MIN_WITHDRAWAL_AMOUNT, L1_RECIPIENT_ONE, GAS_LIMIT, address(0));

        vm.expectRevert(RevShareContractsUpgrader.ChainFeesRecipientCannotBeZeroAddress.selector);
        upgrader.setupRevShare(configs);
    }

    /// @notice Test that setupRevShare reverts when gas limit is zero
    function test_setupRevShare_whenGasLimitIsZero_reverts() public {
        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] =
            _createRevShareConfig(PORTAL_ONE, MIN_WITHDRAWAL_AMOUNT, L1_RECIPIENT_ONE, 0, CHAIN_FEES_RECIPIENT_ONE);

        vm.expectRevert(RevShareContractsUpgrader.GasLimitCannotBeZero.selector);
        upgrader.setupRevShare(configs);
    }

    /// @notice Fuzz test successful setupRevShare with single chain
    function testFuzz_setupRevShare_singleChain_succeeds(
        address _portal,
        uint256 _minWithdrawalAmount,
        address _l1Recipient,
        uint32 _gasLimit,
        address _chainFeesRecipient
    ) public {
        // Bound inputs to valid ranges
        assumeNotForgeAddress(_portal);
        _assumeValidAddress(_portal);
        _assumeValidAddress(_l1Recipient);
        _assumeValidAddress(_chainFeesRecipient);
        _gasLimit = uint32(bound(_gasLimit, 1, type(uint32).max));

        RevShareContractsUpgrader.RevShareConfig[] memory configs = new RevShareContractsUpgrader.RevShareConfig[](1);
        configs[0] = _createRevShareConfig(_portal, _minWithdrawalAmount, _l1Recipient, _gasLimit, _chainFeesRecipient);

        // Calculate expected addresses
        bytes memory l1WithdrawerInitCode = bytes.concat(
            FeeSplitterSetup.l1WithdrawerCreationCode, abi.encode(_minWithdrawalAmount, _l1Recipient, _gasLimit)
        );
        address expectedL1Withdrawer = _calculateExpectedCreate2Address("L1Withdrawer", l1WithdrawerInitCode);

        bytes memory calculatorInitCode = bytes.concat(
            FeeSplitterSetup.scRevShareCalculatorCreationCode, abi.encode(expectedL1Withdrawer, _chainFeesRecipient)
        );
        address expectedCalculator = _calculateExpectedCreate2Address("SCRevShareCalculator", calculatorInitCode);

        // Mock all calls (setupRevShare deploys periphery, sets calculator, and configures vaults)
        _mockAndExpectL1WithdrawerDeploy(_portal, _minWithdrawalAmount, _l1Recipient, _gasLimit);
        _mockAndExpectCalculatorDeploy(_portal, expectedL1Withdrawer, _chainFeesRecipient);
        _mockAndExpectFeeSplitterSetCalculator(_portal, expectedCalculator);
        _mockAndExpectAllVaultSetters(_portal);

        // Expect event
        vm.expectEmit(address(upgrader));
        emit ChainProcessed(_portal, 0);

        // Execute
        upgrader.setupRevShare(configs);
    }

    /// @notice Fuzz test successful setupRevShare with multiple chains
    function testFuzz_setupRevShare_multipleChains_succeeds(uint8 _numChains, uint256 _seed) public {
        // Bound to reasonable range: 2-50 chains
        _numChains = uint8(bound(_numChains, 2, 50));

        // Setup configs array
        RevShareContractsUpgrader.RevShareConfig[] memory configs =
            new RevShareContractsUpgrader.RevShareConfig[](_numChains);

        // Generate random configs and setup mocks for each chain
        for (uint256 i; i < _numChains; ++i) {
            // Use seed + index to generate pseudo-random but deterministic values
            uint256 chainSeed = uint256(keccak256(abi.encode(_seed, i)));

            // Generate random but valid addresses (non-zero)
            address portal = makeAddr(string.concat("portal_", vm.toString(chainSeed)));
            address l1Recipient = makeAddr(string.concat("l1recipient_", vm.toString(chainSeed)));
            address chainFeeRecipient = makeAddr(string.concat("chainfee_", vm.toString(chainSeed)));

            // Generate random config values
            uint256 minWithdrawalAmount =
                bound(uint256(keccak256(abi.encode(chainSeed, "minwithdrawal"))), 1, type(uint256).max);
            uint32 gasLimit = uint32(bound(uint256(keccak256(abi.encode(chainSeed, "gaslimit"))), 1, type(uint32).max));

            configs[i] = _createRevShareConfig(portal, minWithdrawalAmount, l1Recipient, gasLimit, chainFeeRecipient);

            // Calculate expected addresses for this chain
            bytes memory l1WithdrawerInitCode = bytes.concat(
                FeeSplitterSetup.l1WithdrawerCreationCode, abi.encode(minWithdrawalAmount, l1Recipient, gasLimit)
            );
            address expectedL1Withdrawer = _calculateExpectedCreate2Address("L1Withdrawer", l1WithdrawerInitCode);

            bytes memory calculatorInitCode = bytes.concat(
                FeeSplitterSetup.scRevShareCalculatorCreationCode, abi.encode(expectedL1Withdrawer, chainFeeRecipient)
            );
            address expectedCalculator = _calculateExpectedCreate2Address("SCRevShareCalculator", calculatorInitCode);

            // Setup mocks for this chain (setupRevShare deploys periphery, sets calculator, and configures vaults)
            _mockAndExpectL1WithdrawerDeploy(portal, minWithdrawalAmount, l1Recipient, gasLimit);
            _mockAndExpectCalculatorDeploy(portal, expectedL1Withdrawer, chainFeeRecipient);
            _mockAndExpectFeeSplitterSetCalculator(portal, expectedCalculator);
            _mockAndExpectAllVaultSetters(portal);

            // Expect event for this chain
            vm.expectEmit(address(upgrader));
            emit ChainProcessed(portal, i);
        }

        // Execute once with all chains
        upgrader.setupRevShare(configs);
    }
}
