// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";
import {SimpleTaskBase} from "src/tasks/types/SimpleTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {RevShareCodeRepo} from "src/libraries/RevShareCodeRepo.sol";
import {RevShareGasLimits} from "src/libraries/RevShareGasLimits.sol";
import {Utils} from "src/libraries/Utils.sol";

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
    function initialize(address _sharesCalculator) external;
}

/// @notice Interface for the vaults in L2.
interface IFeeVault {
    function initialize(address _recipient, uint256 _minWithdrawalAmount, uint8 _withdrawalNetwork) external;
}

/// @notice Interface for ProxyAdmin.
interface IProxyAdmin {
    function upgrade(address payable _proxy, address _implementation) external;
    function upgradeAndCall(address payable _proxy, address _implementation, bytes memory _data) external;
}

/// @notice A template contract for chains to upgrade to the Revenue Share v1.0.0 implementation.
contract RevenueShareV100UpgradePath is SimpleTaskBase {
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
    /// @notice Address of the ProxyAdmin predeploy on L2.
    address internal constant PROXY_ADMIN = 0x4200000000000000000000000000000000000018;

    /// @notice Used to validate calls made to the OptimismPortal.
    mapping(bytes32 => uint8) internal _callsToPortal;

    /// @notice The withdrawal network configuration for each fee vault.
    uint8 baseFeeVaultWithdrawalNetwork;
    uint8 l1FeeVaultWithdrawalNetwork;
    uint8 sequencerFeeVaultWithdrawalNetwork;
    uint8 operatorFeeVaultWithdrawalNetwork;

    /// @notice The recipient configuration for each fee vault.
    address baseFeeVaultRecipient;
    address l1FeeVaultRecipient;
    address sequencerFeeVaultRecipient;
    address operatorFeeVaultRecipient;

    /// @notice The minimum withdrawal amount configuration for each fee vault.
    uint256 baseFeeVaultMinWithdrawalAmount;
    uint256 l1FeeVaultMinWithdrawalAmount;
    uint256 sequencerFeeVaultMinWithdrawalAmount;
    uint256 operatorFeeVaultMinWithdrawalAmount;

    /// @notice The configuration for the l1 withdrawer
    uint256 public l1WithdrawerMinWithdrawalAmount;
    // TODO(17505): This address is expected to be set to the appropriate FeesDepositor address once deployed.
    address public l1WithdrawerRecipient;
    /// @notice The gas limit for the L1 Withdrawer.
    uint32 public l1WithdrawerGasLimit;

    /// @notice The configuration for sc rev share calculator.
    address public scRevShareCalcChainFeesRecipient;

    /// @notice The address of the OptimismPortal through which we are making the deposit txns
    address public portal;

    /// @notice The salt seed to be used for the L2 deployments
    string public saltSeed;

    /// @notice Config value indicating if the chain is opting in to use FeeSplitter
    bool public optInRevenueShare;

    /// @notice The address the OperatorFeeVault implementation is deployed to.
    address internal _operatorFeeVaultPrecalculatedAddress;
    /// @notice The calldata sent to the OptimismPortal to deploy the OperatorFeeVault.
    bytes internal _operatorFeeVaultCalldata;

    /// @notice The address the SequencerFeeVault implementation is deployed to.
    address internal _sequencerFeeVaultPrecalculatedAddress;
    /// @notice The calldata sent to the OptimismPortal to deploy the SequencerFeeVault.
    bytes internal _sequencerFeeVaultCalldata;

    /// @notice The address the BaseFeeVault implementation is deployed to.
    address internal _baseFeeVaultPrecalculatedAddress;
    /// @notice The calldata sent to the OptimismPortal to deploy the BaseFeeVault.
    bytes internal _baseFeeVaultCalldata;

    /// @notice The address the L1FeeVault implementation is deployed to.
    address internal _l1FeeVaultPrecalculatedAddress;
    /// @notice The calldata sent to the OptimismPortal to deploy the L1FeeVault.
    bytes internal _l1FeeVaultCalldata;

    /// @notice The address the L1Withdrawer implementation is deployed to.
    /// @notice In case the chain is not opting to use the Fee Splitter this will be address(0).
    address internal _l1WithdrawerPrecalculatedAddress;
    /// @notice The calldata sent to the OptimismPortal to deploy the L1Withdrawer.
    bytes internal _l1WithdrawerCalldata;

    /// @notice The address the SuperchainRevenueShareCalculator implementation is deployed to.
    /// @notice In case the chain is not opting to use the Fee Splitter this will be address(0).
    address internal _scRevShareCalculatorPrecalculatedAddress;
    /// @notice The calldata sent to the OptimismPortal to deploy the SuperchainRevenueShareCalculator.
    bytes internal _scRevShareCalculatorCalldata;

    /// @notice The address the FeeSplitter implementation is deployed to.
    address internal _feeSplitterPrecalculatedAddress;
    /// @notice The calldata sent to the OptimismPortal to deploy the FeeSplitter.
    bytes internal _feeSplitterCalldata;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory _storageWrites = new string[](1);
        _storageWrites[0] = "OptimismPortal";
        return _storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {
        string[] memory _balanceChanges = new string[](1);
        _balanceChanges[0] = "OptimismPortal";
        return _balanceChanges;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory _taskConfigFilePath, address) internal override {
        string memory _toml = vm.readFile(_taskConfigFilePath);

        portal = _toml.readAddress(".portal");
        require(portal != address(0), "portal must be set in config");

        saltSeed = _toml.readString(".saltSeed");
        require(bytes(saltSeed).length != 0, "saltSeed must be set in the config");

        optInRevenueShare = _toml.readBool(".optInRevenueShare");

        if (!optInRevenueShare) {
            // These configs are only relevant in case the chain is not opting to use the Fee Splitter

            // Check for Fee Vaults config
            // BaseFeeVault
            baseFeeVaultWithdrawalNetwork = uint8(_toml.readUint(".baseFeeVaultWithdrawalNetwork"));
            require(
                baseFeeVaultWithdrawalNetwork == 0 || baseFeeVaultWithdrawalNetwork == 1,
                "baseFeeVaultWithdrawalNetwork must be set to either 0 (L1) or 1 (L2) in config"
            );

            baseFeeVaultRecipient = _toml.readAddress(".baseFeeVaultRecipient");
            require(baseFeeVaultRecipient != address(0), "baseFeeVaultRecipient must be set in config");

            baseFeeVaultMinWithdrawalAmount = _toml.readUint(".baseFeeVaultMinWithdrawalAmount");

            // L1FeeVault
            l1FeeVaultWithdrawalNetwork = uint8(_toml.readUint(".l1FeeVaultWithdrawalNetwork"));
            require(
                l1FeeVaultWithdrawalNetwork == 0 || l1FeeVaultWithdrawalNetwork == 1,
                "l1FeeVaultWithdrawalNetwork must be set to either 0 (L1) or 1 (L2) in config"
            );

            l1FeeVaultRecipient = _toml.readAddress(".l1FeeVaultRecipient");
            require(l1FeeVaultRecipient != address(0), "l1FeeVaultRecipient must be set in config");

            l1FeeVaultMinWithdrawalAmount = _toml.readUint(".l1FeeVaultMinWithdrawalAmount");

            // SequencerFeeVault
            sequencerFeeVaultWithdrawalNetwork = uint8(_toml.readUint(".sequencerFeeVaultWithdrawalNetwork"));
            require(
                sequencerFeeVaultWithdrawalNetwork == 0 || sequencerFeeVaultWithdrawalNetwork == 1,
                "sequencerFeeVaultWithdrawalNetwork must be set to either 0 (L1) or 1 (L2) in config"
            );

            sequencerFeeVaultRecipient = _toml.readAddress(".sequencerFeeVaultRecipient");
            require(sequencerFeeVaultRecipient != address(0), "sequencerFeeVaultRecipient must be set in config");

            sequencerFeeVaultMinWithdrawalAmount = _toml.readUint(".sequencerFeeVaultMinWithdrawalAmount");

            // OperatorFeeVault
            operatorFeeVaultWithdrawalNetwork = uint8(_toml.readUint(".operatorFeeVaultWithdrawalNetwork"));
            require(
                operatorFeeVaultWithdrawalNetwork == 0 || operatorFeeVaultWithdrawalNetwork == 1,
                "operatorFeeVaultWithdrawalNetwork must be set to either 0 (L1) or 1 (L2) in config"
            );

            operatorFeeVaultRecipient = _toml.readAddress(".operatorFeeVaultRecipient");
            require(operatorFeeVaultRecipient != address(0), "operatorFeeVaultRecipient must be set in config");

            operatorFeeVaultMinWithdrawalAmount = _toml.readUint(".operatorFeeVaultMinWithdrawalAmount");
        } else {
            // Use the Fee Splitter predeploy, L2 Withdrawal Network and 0 for all the vaults

            // BaseFeeVault
            baseFeeVaultWithdrawalNetwork = 1;
            baseFeeVaultRecipient = FEE_SPLITTER;
            baseFeeVaultMinWithdrawalAmount = 0;

            // SequencerFeeVault
            sequencerFeeVaultWithdrawalNetwork = 1;
            sequencerFeeVaultRecipient = FEE_SPLITTER;
            sequencerFeeVaultMinWithdrawalAmount = 0;

            // L1FeeVault
            l1FeeVaultWithdrawalNetwork = 1;
            l1FeeVaultRecipient = FEE_SPLITTER;
            l1FeeVaultMinWithdrawalAmount = 0;

            // OperatorFeeVault
            operatorFeeVaultWithdrawalNetwork = 1;
            operatorFeeVaultRecipient = FEE_SPLITTER;
            operatorFeeVaultMinWithdrawalAmount = 0;

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
            _l1WithdrawerCalldata =
                abi.encodeCall(ICreate2Deployer.deploy, (0, _getSalt(saltSeed, "L1Withdrawer"), _l1WithdrawerInitCode));
            _l1WithdrawerPrecalculatedAddress =
                Utils.getCreate2Address(_getSalt(saltSeed, "L1Withdrawer"), _l1WithdrawerInitCode, CREATE2_DEPLOYER);
            // Expected calls for L1 Withdrawer: 1 (deploy)
            _incrementCallsToPortal(
                abi.encodeCall(
                    IOptimismPortal2.depositTransaction,
                    (
                        address(CREATE2_DEPLOYER),
                        0,
                        RevShareGasLimits.L1_WITHDRAWER_DEPLOYMENT_GAS_LIMIT,
                        false,
                        _l1WithdrawerCalldata
                    )
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
            _scRevShareCalculatorCalldata = abi.encodeCall(
                ICreate2Deployer.deploy, (0, _getSalt(saltSeed, "SCRevShareCalculator"), _scRevShareCalculatorInitCode)
            );

            _scRevShareCalculatorPrecalculatedAddress = Utils.getCreate2Address(
                _getSalt(saltSeed, "SCRevShareCalculator"), _scRevShareCalculatorInitCode, CREATE2_DEPLOYER
            );

            // Expected calls for SC Rev Shares Calculator: 1 (deploy)
            _incrementCallsToPortal(
                abi.encodeCall(
                    IOptimismPortal2.depositTransaction,
                    (
                        address(CREATE2_DEPLOYER),
                        0,
                        RevShareGasLimits.SC_REV_SHARE_CALCULATOR_DEPLOYMENT_GAS_LIMIT,
                        false,
                        _scRevShareCalculatorCalldata
                    )
                )
            );
        }

        // Calculate addresses and data to deploy vaults
        // Calculate addresses and data to deploy OperatorFeeVault
        bytes memory _operatorFeeVaultInitCode = RevShareCodeRepo.operatorFeeVaultCreationCode;
        _operatorFeeVaultPrecalculatedAddress =
            Utils.getCreate2Address(_getSalt(saltSeed, "OperatorFeeVault"), _operatorFeeVaultInitCode, CREATE2_DEPLOYER);

        _operatorFeeVaultCalldata = abi.encodeCall(
            ICreate2Deployer.deploy, (0, _getSalt(saltSeed, "OperatorFeeVault"), _operatorFeeVaultInitCode)
        );
        // Expected calls for OperatorFeeVault: 2 (deploy + upgradeAndCall)
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(CREATE2_DEPLOYER),
                    0,
                    RevShareGasLimits.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
                    false,
                    _operatorFeeVaultCalldata
                )
            )
        );
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(PROXY_ADMIN),
                    0,
                    RevShareGasLimits.UPGRADE_GAS_LIMIT,
                    false,
                    abi.encodeCall(
                        IProxyAdmin.upgradeAndCall,
                        (
                            payable(OPERATOR_FEE_VAULT),
                            address(_operatorFeeVaultPrecalculatedAddress),
                            abi.encodeCall(
                                IFeeVault.initialize,
                                (
                                    operatorFeeVaultRecipient,
                                    operatorFeeVaultMinWithdrawalAmount,
                                    operatorFeeVaultWithdrawalNetwork
                                )
                            )
                        )
                    )
                )
            )
        );

        // Calculate addresses and data to deploy SequencerFeeVault
        bytes memory _sequencerFeeVaultInitCode = RevShareCodeRepo.sequencerFeeVaultCreationCode;
        _sequencerFeeVaultPrecalculatedAddress = Utils.getCreate2Address(
            _getSalt(saltSeed, "SequencerFeeVault"), _sequencerFeeVaultInitCode, CREATE2_DEPLOYER
        );
        _sequencerFeeVaultCalldata = abi.encodeCall(
            ICreate2Deployer.deploy, (0, _getSalt(saltSeed, "SequencerFeeVault"), _sequencerFeeVaultInitCode)
        );

        // Expected calls for SequencerFeeVault: 2 (deploy + upgrade)
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(CREATE2_DEPLOYER),
                    0,
                    RevShareGasLimits.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
                    false,
                    _sequencerFeeVaultCalldata
                )
            )
        );
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(PROXY_ADMIN),
                    0,
                    RevShareGasLimits.UPGRADE_GAS_LIMIT,
                    false,
                    abi.encodeCall(
                        IProxyAdmin.upgradeAndCall,
                        (
                            payable(SEQUENCER_FEE_VAULT),
                            address(_sequencerFeeVaultPrecalculatedAddress),
                            abi.encodeCall(
                                IFeeVault.initialize,
                                (
                                    sequencerFeeVaultRecipient,
                                    sequencerFeeVaultMinWithdrawalAmount,
                                    sequencerFeeVaultWithdrawalNetwork
                                )
                            )
                        )
                    )
                )
            )
        );

        // Calculate addresses and data to deploy BaseFeeVault
        bytes memory _baseFeeVaultInitCode = RevShareCodeRepo.baseFeeVaultCreationCode;
        _baseFeeVaultPrecalculatedAddress =
            Utils.getCreate2Address(_getSalt(saltSeed, "BaseFeeVault"), _baseFeeVaultInitCode, CREATE2_DEPLOYER);
        _baseFeeVaultCalldata =
            abi.encodeCall(ICreate2Deployer.deploy, (0, _getSalt(saltSeed, "BaseFeeVault"), _baseFeeVaultInitCode));

        // Expected calls for BaseFeeVault: 2 (deploy + upgradeAndCall)
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(CREATE2_DEPLOYER),
                    0,
                    RevShareGasLimits.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
                    false,
                    _baseFeeVaultCalldata
                )
            )
        );
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(PROXY_ADMIN),
                    0,
                    RevShareGasLimits.UPGRADE_GAS_LIMIT,
                    false,
                    abi.encodeCall(
                        IProxyAdmin.upgradeAndCall,
                        (
                            payable(BASE_FEE_VAULT),
                            address(_baseFeeVaultPrecalculatedAddress),
                            abi.encodeCall(
                                IFeeVault.initialize,
                                (baseFeeVaultRecipient, baseFeeVaultMinWithdrawalAmount, baseFeeVaultWithdrawalNetwork)
                            )
                        )
                    )
                )
            )
        );

        // Calculate addresses and data to deploy L1FeeVault
        bytes memory _l1FeeVaultInitCode = RevShareCodeRepo.l1FeeVaultCreationCode;
        _l1FeeVaultPrecalculatedAddress =
            Utils.getCreate2Address(_getSalt(saltSeed, "L1FeeVault"), _l1FeeVaultInitCode, CREATE2_DEPLOYER);
        _l1FeeVaultCalldata =
            abi.encodeCall(ICreate2Deployer.deploy, (0, _getSalt(saltSeed, "L1FeeVault"), _l1FeeVaultInitCode));

        // Expected calls for L1FeeVault: 2 (deploy + upgradeAndCall)
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(CREATE2_DEPLOYER),
                    0,
                    RevShareGasLimits.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
                    false,
                    _l1FeeVaultCalldata
                )
            )
        );
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(PROXY_ADMIN),
                    0,
                    RevShareGasLimits.UPGRADE_GAS_LIMIT,
                    false,
                    abi.encodeCall(
                        IProxyAdmin.upgradeAndCall,
                        (
                            payable(L1_FEE_VAULT),
                            address(_l1FeeVaultPrecalculatedAddress),
                            abi.encodeCall(
                                IFeeVault.initialize,
                                (l1FeeVaultRecipient, l1FeeVaultMinWithdrawalAmount, l1FeeVaultWithdrawalNetwork)
                            )
                        )
                    )
                )
            )
        );

        // Calculate addresses and data to deploy Fee Splitter
        _feeSplitterCalldata = abi.encodeCall(
            ICreate2Deployer.deploy, (0, _getSalt(saltSeed, "FeeSplitter"), RevShareCodeRepo.feeSplitterCreationCode)
        );
        _feeSplitterPrecalculatedAddress = Utils.getCreate2Address(
            _getSalt(saltSeed, "FeeSplitter"), RevShareCodeRepo.feeSplitterCreationCode, CREATE2_DEPLOYER
        );

        // Expected calls for FeeSplitter: 2 (deploy + upgradeAndCall)
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(CREATE2_DEPLOYER),
                    0,
                    RevShareGasLimits.FEE_SPLITTER_DEPLOYMENT_GAS_LIMIT,
                    false,
                    _feeSplitterCalldata
                )
            )
        );
        _incrementCallsToPortal(
            abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    address(PROXY_ADMIN),
                    0,
                    RevShareGasLimits.UPGRADE_GAS_LIMIT,
                    false,
                    abi.encodeCall(
                        IProxyAdmin.upgradeAndCall,
                        (
                            payable(FEE_SPLITTER),
                            address(_feeSplitterPrecalculatedAddress),
                            abi.encodeCall(IFeeSplitter.initialize, (_scRevShareCalculatorPrecalculatedAddress))
                        )
                    )
                )
            )
        );
    }

    /// @notice Before implementing the `_build` function, template developers must consider the following:
    /// 1. Which Multicall contract does this template use — `Multicall3` or `Multicall3Delegatecall`?
    /// 2. Based on the contract, should the target be called using `call` or `delegatecall`?
    /// 3. Ensure that the call to the target uses the appropriate method (`call` or `delegatecall`) accordingly.
    /// Guidelines:
    /// - `Multicall3`:
    ///  If the template directly inherits from `L2TaskBase` or `SimpleTaskBase`, it uses the `Multicall3` contract.
    ///  In this case, calls to the target **must** use `call`, e.g.:
    ///  ` dgm.setRespectedGameType(IOptimismPortal2(payable(portalAddress)), cfg[chainId].gameType);`
    /// WARNING: Any state written to in this function will be reverted after the build function has been run.
    /// Do not rely on setting global variables in this function.
    function _build(address) internal override {
        if (optInRevenueShare) {
            // Deploy L1 Withdrawer
            IOptimismPortal2(payable(portal)).depositTransaction(
                address(CREATE2_DEPLOYER),
                0,
                RevShareGasLimits.L1_WITHDRAWER_DEPLOYMENT_GAS_LIMIT,
                false,
                _l1WithdrawerCalldata
            );

            // Deploy SC Rev Share Calculator
            IOptimismPortal2(payable(portal)).depositTransaction(
                address(CREATE2_DEPLOYER),
                0,
                RevShareGasLimits.SC_REV_SHARE_CALCULATOR_DEPLOYMENT_GAS_LIMIT,
                false,
                _scRevShareCalculatorCalldata
            );
        }

        _deployFeeSplitter();
        _deployFeeVaults();
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal override {
        MultisigTaskPrinter.printTitle("Validating calls to portal");
        // Expected portal calls: 10 (base vault operations + fee splitter)
        // + 2 (revenue share: L1 withdrawer + calculator) if opting in
        uint256 _expectedCallsToPortal = optInRevenueShare ? 12 : 10;
        uint256 _actualCallsToPortal = 0;
        for (uint256 i = 0; i < _actions.length; i++) {
            Action memory action = _actions[i];
            if (action.target == address(portal) && action.arguments.length > 0) {
                _verifyAndDecrementCallsToPortal(action.arguments);
                _actualCallsToPortal += 1;
            }
        }

        require(_actualCallsToPortal == _expectedCallsToPortal, "Invalid number of calls to portal");
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}

    /// @notice Deploys the fee vaults implementation and upgrades the proxies to the calculated addresses.
    function _deployFeeVaults() private {
        // Deploy the fee vaults
        // Deploy the operator fee vault
        IOptimismPortal2(payable(portal)).depositTransaction(
            address(CREATE2_DEPLOYER),
            0,
            RevShareGasLimits.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
            false,
            _operatorFeeVaultCalldata
        );
        IOptimismPortal2(payable(portal)).depositTransaction(
            address(PROXY_ADMIN),
            0,
            RevShareGasLimits.UPGRADE_GAS_LIMIT,
            false,
            abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    payable(OPERATOR_FEE_VAULT),
                    address(_operatorFeeVaultPrecalculatedAddress),
                    abi.encodeCall(
                        IFeeVault.initialize,
                        (
                            operatorFeeVaultRecipient,
                            operatorFeeVaultMinWithdrawalAmount,
                            operatorFeeVaultWithdrawalNetwork
                        )
                    )
                )
            )
        );

        // Deploy the sequencer fee vault
        IOptimismPortal2(payable(portal)).depositTransaction(
            address(CREATE2_DEPLOYER),
            0,
            RevShareGasLimits.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
            false,
            _sequencerFeeVaultCalldata
        );
        IOptimismPortal2(payable(portal)).depositTransaction(
            address(PROXY_ADMIN),
            0,
            RevShareGasLimits.UPGRADE_GAS_LIMIT,
            false,
            abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    payable(SEQUENCER_FEE_VAULT),
                    address(_sequencerFeeVaultPrecalculatedAddress),
                    abi.encodeCall(
                        IFeeVault.initialize,
                        (
                            sequencerFeeVaultRecipient,
                            sequencerFeeVaultMinWithdrawalAmount,
                            sequencerFeeVaultWithdrawalNetwork
                        )
                    )
                )
            )
        );

        // Deploy the base fee vault
        IOptimismPortal2(payable(portal)).depositTransaction(
            address(CREATE2_DEPLOYER),
            0,
            RevShareGasLimits.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT,
            false,
            _baseFeeVaultCalldata
        );
        IOptimismPortal2(payable(portal)).depositTransaction(
            address(PROXY_ADMIN),
            0,
            RevShareGasLimits.UPGRADE_GAS_LIMIT,
            false,
            abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    payable(BASE_FEE_VAULT),
                    address(_baseFeeVaultPrecalculatedAddress),
                    abi.encodeCall(
                        IFeeVault.initialize,
                        (baseFeeVaultRecipient, baseFeeVaultMinWithdrawalAmount, baseFeeVaultWithdrawalNetwork)
                    )
                )
            )
        );

        // Deploy the l1 fee vault
        IOptimismPortal2(payable(portal)).depositTransaction(
            address(CREATE2_DEPLOYER), 0, RevShareGasLimits.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT, false, _l1FeeVaultCalldata
        );
        IOptimismPortal2(payable(portal)).depositTransaction(
            address(PROXY_ADMIN),
            0,
            RevShareGasLimits.UPGRADE_GAS_LIMIT,
            false,
            abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    payable(L1_FEE_VAULT),
                    address(_l1FeeVaultPrecalculatedAddress),
                    abi.encodeCall(
                        IFeeVault.initialize,
                        (l1FeeVaultRecipient, l1FeeVaultMinWithdrawalAmount, l1FeeVaultWithdrawalNetwork)
                    )
                )
            )
        );
    }

    /// @notice Deploys the fee splitter implementation using Create2.
    function _deployFeeSplitter() private {
        // Deploy Fee Splitter
        IOptimismPortal2(payable(portal)).depositTransaction(
            address(CREATE2_DEPLOYER),
            0,
            RevShareGasLimits.FEE_SPLITTER_DEPLOYMENT_GAS_LIMIT,
            false,
            _feeSplitterCalldata
        );

        IOptimismPortal2(payable(portal)).depositTransaction(
            address(PROXY_ADMIN),
            0,
            RevShareGasLimits.UPGRADE_GAS_LIMIT,
            false,
            abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    payable(FEE_SPLITTER),
                    address(_feeSplitterPrecalculatedAddress),
                    abi.encodeCall(IFeeSplitter.initialize, (_scRevShareCalculatorPrecalculatedAddress))
                )
            )
        );
    }

    function _incrementCallsToPortal(bytes memory _calldata) private {
        _callsToPortal[keccak256(_calldata)] += 1;
    }

    function _verifyAndDecrementCallsToPortal(bytes memory _calldata) private {
        bytes32 _calldataHash = keccak256(_calldata);
        require(_callsToPortal[_calldataHash] > 0, "Invalid number of calls with this calldata");
        _callsToPortal[_calldataHash] -= 1;
    }

    function _getSalt(string memory _prefix, string memory _suffix) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes(_prefix), bytes(":"), bytes(_suffix)));
    }
}
