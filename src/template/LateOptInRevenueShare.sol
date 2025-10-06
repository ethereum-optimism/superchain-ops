// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";

import {SimpleTaskBase} from "src/tasks/types/SimpleTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {RevShareCodeRepo} from "src/libraries/RevShareCodeRepo.sol";
import {Utils} from "src/libraries/Utils.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";

/// @notice Interface for the OptimismPortal2 in L1. This is the main interaction point for the template.
interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

/// @notice Interface of the Create2 Preinstall in L2.
interface ICreate2Deployer {
    function deploy(uint256 _value, bytes32 _salt, bytes memory _code) external;
}

/// @notice Interface for the FeeSplitter in L2.
interface IFeeSplitter {
    function setSharesCalculator(address _newSharesCalculator) external;
}

/// @notice Interface for the FeeVault in L2.
interface IFeeVault {
    function setMinWithdrawalAmount(uint256 _newMinWithdrawalAmount) external;
    function setRecipient(address _newRecipient) external;
    function setWithdrawalNetwork(uint8 _newWithdrawalNetwork) external;
}

/// @notice A template for chain operators who initially opted out of revenue sharing to enable it without deploying new contracts.
///         Key Features:
///         - No New Deployments: Configures existing predeployed fee vaults and fee splitter
///         - Flexible Calculator: Use custom calculator or deploy default SuperchainRevSharesCalculator implementation
///         - Complete Vault Setup: Configures Base, Sequencer, L1, and Operator fee vaults
///         - L1 Withdrawer Support: Optional deployment with configurable parameters
contract LateOptInRevenueShare is SimpleTaskBase {
    using LibString for string;
    using stdToml for string;

    /// @notice Address of the Create2Deployer Preinstall on L2.
    address internal constant CREATE2_DEPLOYER = 0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2;
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
    /// @notice The default minimum withdrawal amount for the FeeVault once part of the Revenue Share system.
    uint256 public constant FEE_VAULT_MIN_WITHDRAWAL_AMOUNT = 0;
    /// @notice The default withdrawal network for the FeeVault once part of the Revenue Share system, 0 = L1, 1 = L2
    uint8 public constant FEE_VAULT_WITHDRAWAL_NETWORK = 1;
    /// @notice The default recipient for the FeeVault once part of the Revenue Share system.
    address public constant FEE_VAULT_RECIPIENT = FEE_SPLITTER;

    /// @notice The portal we are targeting for L2 calls.
    address public portal;

    /// @notice Whether to use a configured calculator for the Revenue Share system instead of deploying a new, default one.
    bool public useOwnCalculator;

    /// @notice The address of the configured calculator for the Revenue Share system.
    ///         IMPORTANT:In case the chain is opting to use its own implementation this is the
    ///         address configured in the config and a precalculated address of the implementation otherwise.
    address public calculator;

    /// @notice Optional parameters in case we will use a new deployment of the default SuperchainRevenueShareCalculator.

    /// @notice The address of the configured l1 withdrawer for the calculator.
    address public l1WithdrawerPrecalculatedAddress;
    /// @notice The address of the configured chain fees recipient for the calculator.
    address public scRevShareCalcChainFeesRecipient;

    /// @notice The configuration for the l1 withdrawer
    uint256 public l1WithdrawerMinWithdrawalAmount;
    // TODO(17505): This address is expected to be set to the appropriate FeesDepositor address once deployed.
    address public l1WithdrawerRecipient;
    /// @notice The gas limit for the L1 Withdrawer.
    uint32 public l1WithdrawerGasLimit;

    /// @notice The salt to be used for the L2 deployments
    bytes32 public salt;

    /// @notice The calldata sent to the OptimismPortal to deploy the L1Withdrawer.
    bytes internal _l1WithdrawerCalldata;
    /// @notice The calculated address of the L1Withdrawer.
    address internal _l1WithdrawerPrecalculatedAddress;
    /// @notice The calldata sent to the OptimismPortal to deploy the SC Rev Share Calculator.
    bytes internal _scRevShareCalculatorCalldata;

    /// @notice Used to validate calls made to the OptimismPortal.
    mapping(bytes32 => uint8) internal _callsToPortal;

    /// @notice The gas limit for L2 calls through the portal.
    uint64 public gasLimit;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task. This is an array of
    ///         contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "OptimismPortal";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    ///         IMPORTANT: No contract balances are expected to change during the task.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {
        return new string[](0);
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    ///         State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        string memory _toml = vm.readFile(_taskConfigFilePath);

        portal = simpleAddrRegistry.get("OptimismPortal");
        require(portal != address(0), "OptimismPortal must be set in the addresses block");

        useOwnCalculator = _toml.readBool(".useOwnCalculator");

        uint256 _gasLimitRaw = _toml.readUint(".gasLimit");
        require(_gasLimitRaw > 0, "gasLimit must be set");
        require(_gasLimitRaw <= type(uint64).max, "gasLimit must be less than uint64.max");
        gasLimit = uint64(_gasLimitRaw);

        if (useOwnCalculator) {
            calculator = _toml.readAddress(".calculator");
            require(
                calculator != address(0), "calculator address must be set in config if opting to use own calculator"
            );

            _incrementCallsToPortal(
                abi.encodeCall(
                    IOptimismPortal2.depositTransaction,
                    (
                        address(FEE_SPLITTER),
                        0,
                        gasLimit,
                        false,
                        abi.encodeCall(IFeeSplitter.setSharesCalculator, (calculator))
                    )
                )
            );
        } else {
            string memory _saltSeed = _toml.readString(".saltSeed");
            require(bytes(_saltSeed).length > 0, "saltSeed must be set in config");

            salt = keccak256(abi.encodePacked(_saltSeed));

            l1WithdrawerMinWithdrawalAmount = _toml.readUint(".l1WithdrawerMinWithdrawalAmount");

            l1WithdrawerRecipient = _toml.readAddress(".l1WithdrawerRecipient");
            require(l1WithdrawerRecipient != address(0), "l1WithdrawerRecipient must be set in config");

            uint256 _l1WithdrawerGasLimitRaw = _toml.readUint(".l1WithdrawerGasLimit");
            require(_l1WithdrawerGasLimitRaw > 0, "l1WithdrawerGasLimit must be greater than 0");
            require(_l1WithdrawerGasLimitRaw <= type(uint32).max, "l1WithdrawerGasLimit must be less than uint32.max");
            l1WithdrawerGasLimit = uint32(_l1WithdrawerGasLimitRaw);

            // Calculate addresses and data to deploy L1 Withdrawer
            bytes memory _l1WithdrawerInitCode = bytes.concat(
                RevShareCodeRepo.l1WithdrawerCreationCode,
                abi.encode(l1WithdrawerMinWithdrawalAmount, l1WithdrawerRecipient, l1WithdrawerGasLimit)
            );
            _l1WithdrawerCalldata = abi.encodeCall(ICreate2Deployer.deploy, (0, salt, _l1WithdrawerInitCode));
            _l1WithdrawerPrecalculatedAddress = Utils.getCreate2Address(salt, _l1WithdrawerInitCode, CREATE2_DEPLOYER);

            _incrementCallsToPortal(
                abi.encodeCall(
                    IOptimismPortal2.depositTransaction,
                    (address(CREATE2_DEPLOYER), 0, gasLimit, false, _l1WithdrawerCalldata)
                )
            );

            // Calculate addresses and data to deploy SC Rev Share Calculator
            scRevShareCalcChainFeesRecipient = _toml.readAddress(".scRevShareCalcChainFeesRecipient");
            require(
                scRevShareCalcChainFeesRecipient != address(0), "scRevShareCalcChainFeesRecipient must be set in config"
            );

            bytes memory _scRevShareCalculatorInitCode = bytes.concat(
                RevShareCodeRepo.scRevShareCalculatorCreationCode,
                abi.encode(_l1WithdrawerPrecalculatedAddress, scRevShareCalcChainFeesRecipient)
            );
            _scRevShareCalculatorCalldata =
                abi.encodeCall(ICreate2Deployer.deploy, (0, salt, _scRevShareCalculatorInitCode));

            calculator = Utils.getCreate2Address(salt, _scRevShareCalculatorInitCode, CREATE2_DEPLOYER);

            _incrementCallsToPortal(
                abi.encodeCall(
                    IOptimismPortal2.depositTransaction,
                    (address(CREATE2_DEPLOYER), 0, gasLimit, false, _scRevShareCalculatorCalldata)
                )
            );
        }

        // Take into account the calls for setting up the vaults
        _incrementCallsForVault(BASE_FEE_VAULT);
        _incrementCallsForVault(SEQUENCER_FEE_VAULT);
        _incrementCallsForVault(L1_FEE_VAULT);
        _incrementCallsForVault(OPERATOR_FEE_VAULT);

        // Take into account the calls for setting up the FeeSplitter
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(FEE_SPLITTER),
                    0,
                    gasLimit,
                    false,
                    abi.encodeCall(IFeeSplitter.setSharesCalculator, (calculator))
                )
            )
        );
    }

    function _build(address) internal override {
        if (!useOwnCalculator) {
            // Deploy L1 Withdrawer
            IOptimismPortal2(payable(portal)).depositTransaction(
                address(CREATE2_DEPLOYER), 0, gasLimit, false, _l1WithdrawerCalldata
            );

            // Deploy SC Rev Share Calculator
            IOptimismPortal2(payable(portal)).depositTransaction(
                address(CREATE2_DEPLOYER), 0, gasLimit, false, _scRevShareCalculatorCalldata
            );
        }

        // Set the configuration for the FeeVaults
        _setFeeVaultConfiguration(
            BASE_FEE_VAULT, FEE_VAULT_MIN_WITHDRAWAL_AMOUNT, FEE_VAULT_RECIPIENT, FEE_VAULT_WITHDRAWAL_NETWORK
        );

        _setFeeVaultConfiguration(
            SEQUENCER_FEE_VAULT, FEE_VAULT_MIN_WITHDRAWAL_AMOUNT, FEE_VAULT_RECIPIENT, FEE_VAULT_WITHDRAWAL_NETWORK
        );

        _setFeeVaultConfiguration(
            L1_FEE_VAULT, FEE_VAULT_MIN_WITHDRAWAL_AMOUNT, FEE_VAULT_RECIPIENT, FEE_VAULT_WITHDRAWAL_NETWORK
        );

        _setFeeVaultConfiguration(
            OPERATOR_FEE_VAULT, FEE_VAULT_MIN_WITHDRAWAL_AMOUNT, FEE_VAULT_RECIPIENT, FEE_VAULT_WITHDRAWAL_NETWORK
        );

        // Set the configuration for the FeeSplitter
        bytes memory _feeSplitterSetCalculatorCalldata = abi.encodeCall(IFeeSplitter.setSharesCalculator, (calculator));

        IOptimismPortal2(payable(portal)).depositTransaction(
            address(FEE_SPLITTER), 0, gasLimit, false, _feeSplitterSetCalculatorCalldata
        );
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal override {
        MultisigTaskPrinter.printTitle("Validating calls to portal");
        // Expected calls for portal:
        // - 12 (fee vault operations)
        // - 1 Fee Splitter set calculator
        // - 2 (revenue share: L1 withdrawer + calculator) if they don't use their own calculator and opt to deploy our implementation
        uint256 _expectedCallsToPortal = useOwnCalculator ? 13 : 15;
        uint256 _actualCallsToPortal = 0;
        for (uint256 i = 0; i < _actions.length; i++) {
            Action memory action = _actions[i];
            if (action.target == address(portal) && action.arguments.length > 0) {
                _verifyAndDecrementCallsToPortal(action.arguments);
                _actualCallsToPortal += 1;
            }
        }

        assertEq(_actualCallsToPortal, _expectedCallsToPortal, "Invalid number of calls to portal");
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }

    /// @notice Sets the configuration for the a fee vault.
    function _setFeeVaultConfiguration(
        address _vaultAddress,
        uint256 _minWithdrawalAmount,
        address _recipient,
        uint8 _withdrawalNetwork
    ) internal {
        // Set the minimum withdrawal amount calldata
        bytes memory _minWithdrawalAmountCalldata =
            abi.encodeCall(IFeeVault.setMinWithdrawalAmount, (_minWithdrawalAmount));

        IOptimismPortal2(payable(portal)).depositTransaction(
            _vaultAddress, 0, gasLimit, false, _minWithdrawalAmountCalldata
        );

        // Set the recipient calldata
        bytes memory _recipientCalldata = abi.encodeCall(IFeeVault.setRecipient, (_recipient));

        IOptimismPortal2(payable(portal)).depositTransaction(_vaultAddress, 0, gasLimit, false, _recipientCalldata);

        // Set the withdrawal network calldata
        bytes memory _withdrawalNetworkCalldata = abi.encodeCall(IFeeVault.setWithdrawalNetwork, (_withdrawalNetwork));

        IOptimismPortal2(payable(portal)).depositTransaction(
            _vaultAddress, 0, gasLimit, false, _withdrawalNetworkCalldata
        );
    }

    /// @notice Convenience function to increment the number of calls to the portal for a given vault.
    ///         Takes into account the 3 calls needed to set the configuration for the vault.
    function _incrementCallsForVault(address _vaultAddress) private {
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    _vaultAddress,
                    0,
                    gasLimit,
                    false,
                    abi.encodeCall(IFeeVault.setMinWithdrawalAmount, (FEE_VAULT_MIN_WITHDRAWAL_AMOUNT))
                )
            )
        );
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (_vaultAddress, 0, gasLimit, false, abi.encodeCall(IFeeVault.setRecipient, (FEE_VAULT_RECIPIENT)))
            )
        );
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    _vaultAddress,
                    0,
                    gasLimit,
                    false,
                    abi.encodeCall(IFeeVault.setWithdrawalNetwork, (FEE_VAULT_WITHDRAWAL_NETWORK))
                )
            )
        );
    }

    /// @notice Increments the number of calls to the portal for a given calldata.
    ///         Used to validate the calls executed as expected.
    function _incrementCallsToPortal(bytes memory _calldata) private {
        _callsToPortal[keccak256(_calldata)] += 1;
    }

    /// @notice Verifies and decrements the number of calls to the portal for a given calldata.
    ///         Used to validate the calls executed as expected.
    function _verifyAndDecrementCallsToPortal(bytes memory _calldata) private {
        bytes32 _calldataHash = keccak256(_calldata);
        require(_callsToPortal[_calldataHash] > 0, "Invalid number of calls with this calldata");
        _callsToPortal[_calldataHash] -= 1;
    }
}
