// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {RevenueShareV100UpgradePath} from "src/template/RevenueShareUpgradePath.sol";
import {LateOptInRevenueShare} from "src/template/LateOptInRevenueShare.sol";
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
    LateOptInRevenueShare public lateOptInTemplate;

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
    address internal constant L1_WITHDRAWER = 0x65E05252dd7964dBb722a9fCa24c6a2D7AFbeF57;
    /// @notice Address of the Rev Share Calculator Predeploy on L2.
    address internal constant REV_SHARE_CALCULATOR = 0xa9C1d283Ab6f149853337395E18850B3fF6cf192;
    /// @notice Address of the L1 Withdrawer Predeploy on L2 for late opt in.
    address internal constant L1_WITHDRAWER_LATE_OPT_IN = 0x4427a644D44b1795655847ecB3795caEba83cf7C;
    /// @notice Address of the Rev Share Calculator Predeploy on L2 for late opt in.
    address internal constant REV_SHARE_CALCULATOR_LATE_OPT_IN = 0x28cC7ed36D4788B7248aE2a7a70efC7011DbA7c2;

    function setUp() public {
        _mainnetForkId = vm.createFork("http://127.0.0.1:8545");
        _l2ForkId = vm.createFork("http://127.0.0.1:9545");
        vm.selectFork(_mainnetForkId);
        revenueShareTemplate = new RevenueShareV100UpgradePath();
        lateOptInTemplate = new LateOptInRevenueShare();
    }

    /// @notice Test the integration of the revenue share system when the chain is opting in
    function test_optInRevenueShare_integration() public {
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
        _assertFeeVaultsState(true, ""); // No need to send the config since the chain is opting in
    }

    /// @notice Test the integration of the revenue share system when the chain is opting out
    function test_optOutRevenueShare_integration() public {
        string memory _configPath = "test/tasks/example/eth/019-revenueshare-upgrade-opt-out/config.toml";

        // Step 1: Execute L1 transaction recording logs
        vm.recordLogs();
        revenueShareTemplate.simulate(_configPath, new address[](0));

        // Step 2: Relay messages from L1 to L2
        // Pass true for _isSimulate since simulate() emits events twice
        _relayAllMessages(_l2ForkId, true);

        // Step 3: Assert the state of the L2 contracts
        string memory _config = vm.readFile(_configPath);

        // Fee Splitter: check calculator is set to address(0)
        assertEq(IFeeSplitter(FEE_SPLITTER).sharesCalculator(), address(0));

        // Vaults: vaults configuration should be the same as the ones in the config provided
        // getters for legacy and the new values should be the same
        _assertFeeVaultsState(false, _config);
    }

    /// @notice Test the integration of the revenue share system when the chain is opting out,
    /// then running the late opt in revenue share task with the custom calculator.
    function test_lateOptInRevenueShareCustomCalculator_integration() public {
        string memory _configPath = "test/tasks/example/eth/019-revenueshare-upgrade-opt-out/config.toml";

        // Step 1: Execute L1 transaction recording logs
        vm.recordLogs();
        revenueShareTemplate.simulate(_configPath, new address[](0));

        // Step 2: Relay messages from L1 to L2
        // Pass true for _isSimulate since simulate() emits events twice
        _relayAllMessages(_l2ForkId, true);

        // Step 3: Assert the state of the L2 contracts
        string memory _config = vm.readFile(_configPath);

        // Fee Splitter: check calculator is set to address(0)
        assertEq(IFeeSplitter(FEE_SPLITTER).sharesCalculator(), address(0));

        // Vaults: vaults configuration should be the same as the ones in the config provided
        // getters for legacy and the new values should be the same
        _assertFeeVaultsState(false, _config);

        string memory _configPathCustomCalc =
            "test/tasks/example/eth/017-opt-in-revenue-share-late-custom-calc/config.toml";

        vm.selectFork(_mainnetForkId);

        // Step 4: Execute the late opt in revenue share task
        vm.recordLogs();
        lateOptInTemplate.simulate(_configPathCustomCalc, new address[](0));

        // Step 5: Relay messages from L1 to L2
        // Pass true for _isSimulate since simulate() emits events twice
        _relayAllMessages(_l2ForkId, true);

        // Step 6: Assert the state of the L2 contracts
        string memory _configCustomCalc = vm.readFile(_configPathCustomCalc);

        // Fee Splitter: check calculator is set
        assertEq(IFeeSplitter(FEE_SPLITTER).sharesCalculator(), vm.parseTomlAddress(_configCustomCalc, ".calculator"));

        // Vaults: recipient should be fee splitter, withdrawal network should be L2, min withdrawal amount 0
        // getters for legacy and the new values should be the same
        _assertFeeVaultsState(true, ""); // No need to send the config since the chain is opting in
    }

    /// @notice Test the integration of the revenue share system when the chain is opting out,
    /// then running the late opt in revenue share task with the default calculator.
    function test_lateOptInRevenueShareDefaultCalculator_integration() public {
        string memory _configPath = "test/tasks/example/eth/019-revenueshare-upgrade-opt-out/config.toml";

        // Step 1: Execute L1 transaction recording logs
        vm.recordLogs();
        revenueShareTemplate.simulate(_configPath, new address[](0));

        // Step 2: Relay messages from L1 to L2
        // Pass true for _isSimulate since simulate() emits events twice
        _relayAllMessages(_l2ForkId, true);

        // Step 3: Assert the state of the L2 contracts
        string memory _config = vm.readFile(_configPath);

        // Fee Splitter: check calculator is set to address(0)
        assertEq(IFeeSplitter(FEE_SPLITTER).sharesCalculator(), address(0));

        // Vaults: vaults configuration should be the same as the ones in the config provided
        // getters for legacy and the new values should be the same
        _assertFeeVaultsState(false, _config);

        string memory _configPathDefaultCalc = "test/tasks/example/eth/018-opt-in-revenue-share-late/config.toml";

        vm.selectFork(_mainnetForkId);

        // Step 4: Execute the late opt in revenue share task
        vm.recordLogs();
        lateOptInTemplate.simulate(_configPathDefaultCalc, new address[](0));

        // Step 5: Relay messages from L1 to L2
        // Pass true for _isSimulate since simulate() emits events twice
        _relayAllMessages(_l2ForkId, true);

        // Step 6: Assert the state of the L2 contracts
        string memory _configDefaultCalc = vm.readFile(_configPathDefaultCalc);

        // L1Withdrawer: check withdrawal threshold and fees depositor
        assertEq(
            IL1Withdrawer(L1_WITHDRAWER_LATE_OPT_IN).minWithdrawalAmount(),
            vm.parseTomlUint(_configDefaultCalc, ".l1WithdrawerMinWithdrawalAmount")
        );
        assertEq(
            IL1Withdrawer(L1_WITHDRAWER_LATE_OPT_IN).recipient(),
            vm.parseTomlAddress(_configDefaultCalc, ".l1WithdrawerRecipient")
        );
        assertEq(
            IL1Withdrawer(L1_WITHDRAWER_LATE_OPT_IN).withdrawalGasLimit(),
            vm.parseTomlUint(_configDefaultCalc, ".l1WithdrawerGasLimit")
        );

        // Rev Share Calculator: check chain fees recipient and remainder recipient
        assertEq(
            ISuperchainRevSharesCalculator(REV_SHARE_CALCULATOR_LATE_OPT_IN).shareRecipient(), L1_WITHDRAWER_LATE_OPT_IN
        );
        assertEq(
            ISuperchainRevSharesCalculator(REV_SHARE_CALCULATOR_LATE_OPT_IN).remainderRecipient(),
            vm.parseTomlAddress(_configDefaultCalc, ".scRevShareCalcChainFeesRecipient")
        );

        // Fee Splitter: check calculator is set
        assertEq(IFeeSplitter(FEE_SPLITTER).sharesCalculator(), REV_SHARE_CALCULATOR_LATE_OPT_IN);

        // Vaults: recipient should be fee splitter, withdrawal network should be L2, min withdrawal amount 0
        // getters for legacy and the new values should be the same
        _assertFeeVaultsState(true, ""); // No need to send the config since the chain is opting in
    }

    /// @notice Assert the configuration of the fee vaults
    /// @param _isOptIn Whether the chain is opting in to use the Fee Splitter
    /// @param _config The configuration of the fee vaults
    /// @dev Ensures both the legacy and the new getters return the same value
    function _assertFeeVaultsState(bool _isOptIn, string memory _config) internal view {
        if (_isOptIn) {
            _assertVaultGetters(SEQUENCER_FEE_VAULT, FEE_SPLITTER, WithdrawalNetwork.L2, 0);
            _assertVaultGetters(OPERATOR_FEE_VAULT, FEE_SPLITTER, WithdrawalNetwork.L2, 0);
            _assertVaultGetters(BASE_FEE_VAULT, FEE_SPLITTER, WithdrawalNetwork.L2, 0);
            _assertVaultGetters(L1_FEE_VAULT, FEE_SPLITTER, WithdrawalNetwork.L2, 0);
        } else {
            _assertVaultGetters(
                SEQUENCER_FEE_VAULT,
                vm.parseTomlAddress(_config, ".sequencerFeeVaultRecipient"),
                WithdrawalNetwork(vm.parseTomlUint(_config, ".sequencerFeeVaultWithdrawalNetwork")),
                vm.parseTomlUint(_config, ".sequencerFeeVaultMinWithdrawalAmount")
            );
            _assertVaultGetters(
                OPERATOR_FEE_VAULT,
                vm.parseTomlAddress(_config, ".operatorFeeVaultRecipient"),
                WithdrawalNetwork(vm.parseTomlUint(_config, ".operatorFeeVaultWithdrawalNetwork")),
                vm.parseTomlUint(_config, ".operatorFeeVaultMinWithdrawalAmount")
            );
            _assertVaultGetters(
                BASE_FEE_VAULT,
                vm.parseTomlAddress(_config, ".baseFeeVaultRecipient"),
                WithdrawalNetwork(vm.parseTomlUint(_config, ".baseFeeVaultWithdrawalNetwork")),
                vm.parseTomlUint(_config, ".baseFeeVaultMinWithdrawalAmount")
            );
            _assertVaultGetters(
                L1_FEE_VAULT,
                vm.parseTomlAddress(_config, ".l1FeeVaultRecipient"),
                WithdrawalNetwork(vm.parseTomlUint(_config, ".l1FeeVaultWithdrawalNetwork")),
                vm.parseTomlUint(_config, ".l1FeeVaultMinWithdrawalAmount")
            );
        }
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
