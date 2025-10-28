// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {RevenueShareV100UpgradePath} from "src/template/RevenueShareUpgradePath.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {IntegrationBase} from "./IntegrationBase.t.sol";
import {Test} from "forge-std/Test.sol";

enum WithdrawalNetwork {
    L1,
    L2
}

interface IFeeVault {
    function MIN_WITHDRAWAL_AMOUNT() external view returns (uint256);
    function RECIPIENT() external view returns (address);
    function WITHDRAWAL_NETWORK() external view returns (WithdrawalNetwork);
    function minWithdrawalAmount() external view returns (uint256);
    function recipient() external view returns (address);
    function withdrawalNetwork() external view returns (WithdrawalNetwork);
}

interface IFeeSplitter {
    function sharesCalculator() external view returns (address);
}

interface IL1Withdrawer {
    function minWithdrawalAmount() external view returns (uint256);
    function recipient() external view returns (address);
    function withdrawalGasLimit() external view returns (uint32);
}

interface ISuperchainRevSharesCalculator {
    function shareRecipient() external view returns (address payable);
    function remainderRecipient() external view returns (address payable);
}

contract RevenueShareIntegrationTest is IntegrationBase {
    RevenueShareV100UpgradePath public revenueShareTemplate;

    // Fork IDs
    uint256 internal _mainnetForkId;
    uint256 internal _l2ForkId;

    // L2 predeploys
    /// @notice Address of the Sequencer Fee Vault Predeploy on L2.
    address internal constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    /// @notice Address of the Operator Fee Vault Predeploy on L2.
    address internal constant OPERATOR_FEE_VAULT = 0x420000000000000000000000000000000000001b;
    /// @notice Address of the Base Fee Vault Predeploy on L2.
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    /// @notice Address of the L1 Fee Vault Predeploy on L2.
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;
    /// @notice Address of the FeeSplitter Predeploy on L2.
    address internal constant FEE_SPLITTER = 0x420000000000000000000000000000000000002B;

    // Deployed contracts (precalculated as they are deployed with CREATE2)
    /// @notice Address of the L1 Withdrawer Predeploy on L2.
    address internal constant L1_WITHDRAWER = 0x524E512Dd372C70E7866a7825481385b7b533af0;
    /// @notice Address of the Rev Share Calculator Predeploy on L2.
    address internal constant REV_SHARE_CALCULATOR = 0x72aa66CaA04C9bd83Ecc43c65cff2Cf837EE4BB3;

    function setUp() public {
        _mainnetForkId = vm.createFork("http://127.0.0.1:8545");
        _l2ForkId = vm.createFork("http://127.0.0.1:9545");
        vm.selectFork(_mainnetForkId);
        revenueShareTemplate = new RevenueShareV100UpgradePath();
    }

    /// @notice Test the integration of the revenue share system when the chain is opting in
    function test_revenueShare_defaultCalculator_integration() public {
        string memory _configPath = "test/tasks/example/eth/015-revenue-share-upgrade/config.toml";

        // Step 1: Execute L1 transaction recording logs
        vm.recordLogs();
        revenueShareTemplate.simulate(_configPath, new address[](0));

        // Step 2: Relay messages from L1 to L2
        // Pass true for _isSimulate since simulate() emits events twice
        _relayAllMessages(_l2ForkId, true);

        // Step 3: Assert the state of the L2 contracts
        string memory _config = vm.readFile(_configPath);

        // L1Withdrawer: check withdrawal threshold and fees depositor
        assertEq(
            IL1Withdrawer(L1_WITHDRAWER).minWithdrawalAmount(),
            vm.parseTomlUint(_config, ".l1WithdrawerMinWithdrawalAmount")
        );
        assertEq(IL1Withdrawer(L1_WITHDRAWER).recipient(), vm.parseTomlAddress(_config, ".l1WithdrawerRecipient"));
        assertEq(IL1Withdrawer(L1_WITHDRAWER).withdrawalGasLimit(), vm.parseTomlUint(_config, ".l1WithdrawerGasLimit"));

        // Rev Share Calculator: check chain fees recipient and remainder recipient
        assertEq(ISuperchainRevSharesCalculator(REV_SHARE_CALCULATOR).shareRecipient(), L1_WITHDRAWER);
        assertEq(
            ISuperchainRevSharesCalculator(REV_SHARE_CALCULATOR).remainderRecipient(),
            vm.parseTomlAddress(_config, ".scRevShareCalcChainFeesRecipient")
        );

        // Fee Splitter: check calculator is set
        assertEq(IFeeSplitter(FEE_SPLITTER).sharesCalculator(), REV_SHARE_CALCULATOR);

        // Vaults: recipient should be fee splitter, withdrawal network should be L2, min withdrawal amount 0
        // getters for legacy and the new values should be the same
        _assertFeeVaultsState();
    }

    /// @notice Test the integration of the revenue share system when the chain is opting in with a custom calculator
    function test_revenueShare_customCalculator_integration() public {
        string memory _configPath = "test/tasks/example/eth/017-revenue-share-upgrade-custom-calc/config.toml";

        // Step 1: Execute L1 transaction recording logs
        vm.recordLogs();
        revenueShareTemplate.simulate(_configPath, new address[](0));

        // Step 2: Relay messages from L1 to L2
        // Pass true for _isSimulate since simulate() emits events twice
        _relayAllMessages(_l2ForkId, true);

        // Step 3: Assert the state of the L2 contracts
        string memory _config = vm.readFile(_configPath);

        // L1Withdrawer: check it wasn't deployed
        assertEq(L1_WITHDRAWER.code.length, 0);

        // Rev Share Calculator: check it wasn't deployed
        assertEq(REV_SHARE_CALCULATOR.code.length, 0);

        // Fee Splitter: check calculator is set
        assertEq(IFeeSplitter(FEE_SPLITTER).sharesCalculator(), vm.parseTomlAddress(_config, ".customCalculator"));

        // Vaults: recipient should be fee splitter, withdrawal network should be L2, min withdrawal amount 0
        // getters for legacy and the new values should be the same
        _assertFeeVaultsState();
    }

    /// @notice Assert the configuration of the fee vaults
    /// @dev Ensures both the legacy and the new getters return the same value
    function _assertFeeVaultsState() internal view {
        _assertVaultGetters(SEQUENCER_FEE_VAULT, FEE_SPLITTER, WithdrawalNetwork.L2, 0);
        _assertVaultGetters(OPERATOR_FEE_VAULT, FEE_SPLITTER, WithdrawalNetwork.L2, 0);
        _assertVaultGetters(BASE_FEE_VAULT, FEE_SPLITTER, WithdrawalNetwork.L2, 0);
        _assertVaultGetters(L1_FEE_VAULT, FEE_SPLITTER, WithdrawalNetwork.L2, 0);
    }

    /// @notice Assert the configuration of a fee vault
    /// @param _vault The address of the fee vault
    /// @param _recipient The recipient of the fee vault
    /// @param _withdrawalNetwork The withdrawal network of the fee vault
    /// @param _minWithdrawalAmount The minimum withdrawal amount of the fee vault
    /// @dev Ensures both the legacy and the new getters return the same value
    function _assertVaultGetters(
        address _vault,
        address _recipient,
        WithdrawalNetwork _withdrawalNetwork,
        uint256 _minWithdrawalAmount
    ) internal view {
        assertEq(IFeeVault(_vault).recipient(), _recipient);
        assertEq(uint256(IFeeVault(_vault).withdrawalNetwork()), uint256(_withdrawalNetwork));
        assertEq(IFeeVault(_vault).minWithdrawalAmount(), _minWithdrawalAmount);
        assertEq(IFeeVault(_vault).RECIPIENT(), _recipient);
        assertEq(uint256(IFeeVault(_vault).WITHDRAWAL_NETWORK()), uint256(_withdrawalNetwork));
        assertEq(IFeeVault(_vault).MIN_WITHDRAWAL_AMOUNT(), _minWithdrawalAmount);
    }
}
