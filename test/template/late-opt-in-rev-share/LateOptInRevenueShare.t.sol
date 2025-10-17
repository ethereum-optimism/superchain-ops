// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {LateOptInRevenueShare} from "src/template/LateOptInRevenueShare.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Signatures} from "@base-contracts/script/universal/Signatures.sol";
import {RevShareCodeRepo} from "src/libraries/RevShareCodeRepo.sol";
import {RevShareGasLimits} from "src/libraries/RevShareGasLimits.sol";
import {Utils} from "src/libraries/Utils.sol";

interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface IFeeSplitter {
    function setSharesCalculator(address _newSharesCalculator) external;
}

interface IFeeVault {
    function setMinWithdrawalAmount(uint256 _newMinWithdrawalAmount) external;
    function setRecipient(address _newRecipient) external;
    function setWithdrawalNetwork(uint8 _newWithdrawalNetwork) external;
}

/// @notice Test contract for the LateOptInRevenueShare template.
///         Using config from test/tasks/example/eth/018-opt-in-revenue-share-late/config.toml
contract LateOptInRevenueShareTest is Test {
    LateOptInRevenueShare public template;

    uint256 private constant EXPECTED_ACTIONS_CUSTOM_CALC = 13;
    uint256 private constant EXPECTED_ACTIONS_DEFAULT_CALC = 15;

    // Expected addresses from config
    address public constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    address public constant PROXY_ADMIN_OWNER = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;

    // L2 predeploys
    address internal constant CREATE2_DEPLOYER = 0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2;
    address internal constant FEE_SPLITTER = 0x420000000000000000000000000000000000002B;
    address internal constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    address internal constant OPERATOR_FEE_VAULT = 0x420000000000000000000000000000000000001b;
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;

    // FeeVault configuration
    address internal constant FEE_VAULT_RECIPIENT = 0x420000000000000000000000000000000000002B;
    uint256 internal constant FEE_VAULT_MIN_WITHDRAWAL_AMOUNT = 0;
    uint8 internal constant FEE_VAULT_WITHDRAWAL_NETWORK = 1;

    // L1 Withdrawer configuration
    string internal constant SALT_SEED = "DeploymentSalt";
    address internal constant L1_WITHDRAWER_RECIPIENT = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
    uint256 internal constant L1_WITHDRAWER_MIN_WITHDRAWAL_AMOUNT = 1000000000000000000;
    uint32 internal constant L1_WITHDRAWER_GAS_LIMIT = 300000;
    address internal constant SC_REV_SHARE_CALC_CHAIN_FEES_RECIPIENT = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;

    // Test configuration
    address internal constant TEST_CUSTOM_CALCULATOR = 0x8B0c0c8B8B0c0C8B8b0C0C8b8B0C0c8b8b0C0c8b;

    string public constant configPathCustomCalc =
        "test/tasks/example/eth/017-opt-in-revenue-share-late-custom-calc/config.toml";
    string public constant configPathDefaultCalc = "test/tasks/example/eth/018-opt-in-revenue-share-late/config.toml";

    function setUp() public {
        // Mainnet block 23197819 defined in the config.toml used in these tests
        vm.createSelectFork("mainnet", 23197819);
        template = new LateOptInRevenueShare();
    }

    function test_lateOptInRevenueShare_customCalculator_succeeds() public {
        // Execute the test with custom calculator
        _executeRevenueShareTest(configPathCustomCalc, EXPECTED_ACTIONS_CUSTOM_CALC, 0, TEST_CUSTOM_CALCULATOR);
    }

    function test_lateOptInRevenueShare_defaultCalculator_succeeds() public {
        // Calculate the expected calculator address for default scenario
        address calculator = _calculateDefaultCalculatorAddress();

        // Execute the test with default calculator
        _executeRevenueShareTest(configPathDefaultCalc, EXPECTED_ACTIONS_DEFAULT_CALC, 2, calculator);
    }

    /// @notice Executes the revenue share test with the given parameters
    /// @param configPath Path to the configuration file
    /// @param expectedActions Expected number of actions
    /// @param expectedDeploymentCalls Expected number of deployment calls
    /// @param calculator Calculator address to use
    function _executeRevenueShareTest(
        string memory configPath,
        uint256 expectedActions,
        uint256 expectedDeploymentCalls,
        address calculator
    ) internal {
        // Step 1: Run simulate to prepare everything and get the actions
        (, Action[] memory actions,, address rootSafe) = template.simulate(configPath, new address[](0));

        // Verify we got the expected safe and action count
        assertEq(rootSafe, PROXY_ADMIN_OWNER, "Root safe should be ProxyAdminOwner");
        assertEq(actions.length, expectedActions, "Should have expected number of actions");

        // Step 2: Get the safe's owners
        IGnosisSafe safe = IGnosisSafe(rootSafe);
        address[] memory owners = safe.getOwners();

        // Step 3: Prepare multicall data
        bytes memory multicallData = _prepareMulticallData(actions);

        // Step 4: Get the nonce and compute transaction hash before any state changes
        uint256 nonceBefore = safe.nonce();
        bytes32 txHash = _computeTransactionHash(safe, multicallData, nonceBefore);

        // Step 5: Set up portal call expectations
        _setupPortalExpectations(calculator);

        // Step 6: Execute the Safe transaction
        _executeSafeTransaction(safe, owners, txHash, multicallData);

        // Step 7: Verify the transaction was successful
        assertEq(safe.nonce(), nonceBefore + 1, "Safe nonce should increment");

        // Step 8: Verify the portal calls made to the OptimismPortal
        _verifyPortalCalls(actions, expectedDeploymentCalls);
    }

    /// @notice Calculates the default calculator address for the default scenario
    /// @return The calculated calculator address
    function _calculateDefaultCalculatorAddress() internal pure returns (address) {
        // Calculate addresses for l1Withdrawer and calculator
        bytes memory _l1WithdrawerInitCode = bytes.concat(
            RevShareCodeRepo.l1WithdrawerCreationCode,
            abi.encode(L1_WITHDRAWER_MIN_WITHDRAWAL_AMOUNT, L1_WITHDRAWER_RECIPIENT, L1_WITHDRAWER_GAS_LIMIT)
        );
        address l1Withdrawer =
            Utils.getCreate2Address(keccak256(abi.encodePacked(SALT_SEED)), _l1WithdrawerInitCode, CREATE2_DEPLOYER);

        bytes memory _scRevShareCalculatorInitCode = bytes.concat(
            RevShareCodeRepo.scRevShareCalculatorCreationCode,
            abi.encode(l1Withdrawer, SC_REV_SHARE_CALC_CHAIN_FEES_RECIPIENT)
        );
        return Utils.getCreate2Address(
            keccak256(abi.encodePacked(SALT_SEED)), _scRevShareCalculatorInitCode, CREATE2_DEPLOYER
        );
    }

    /// @notice Prepares multicall data from actions
    /// @param actions Array of actions to convert to multicall
    /// @return The encoded multicall data
    function _prepareMulticallData(Action[] memory actions) internal pure returns (bytes memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](actions.length);
        for (uint256 i = 0; i < actions.length; i++) {
            calls[i] = IMulticall3.Call3Value({
                target: actions[i].target,
                allowFailure: false,
                value: actions[i].value,
                callData: actions[i].arguments
            });
        }
        return abi.encodeCall(IMulticall3.aggregate3Value, (calls));
    }

    /// @notice Computes the transaction hash for the Safe transaction
    /// @param safe The Safe contract instance
    /// @param multicallData The multicall data
    /// @param nonce The current nonce
    /// @return The computed transaction hash
    function _computeTransactionHash(IGnosisSafe safe, bytes memory multicallData, uint256 nonce)
        internal
        view
        returns (bytes32)
    {
        return safe.getTransactionHash(
            template.multicallTarget(),
            0, // value
            multicallData,
            Enum.Operation.DelegateCall,
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            nonce
        );
    }

    /// @notice Sets up portal call expectations
    /// @param calculator The calculator address to expect
    function _setupPortalExpectations(address calculator) internal {
        // Record portal calls using expectCall
        // 3 calls per vault
        address[] memory vaults = new address[](4);
        vaults[0] = BASE_FEE_VAULT;
        vaults[1] = SEQUENCER_FEE_VAULT;
        vaults[2] = L1_FEE_VAULT;
        vaults[3] = OPERATOR_FEE_VAULT;
        _expectVaultSetOperations(vaults, RevShareGasLimits.SETTERS_GAS_LIMIT);

        bytes memory setCalculatorCalldata = abi.encodeCall(
            IOptimismPortal2.depositTransaction,
            (
                FEE_SPLITTER,
                0,
                RevShareGasLimits.SETTERS_GAS_LIMIT,
                false,
                abi.encodeCall(IFeeSplitter.setSharesCalculator, (calculator))
            )
        );
        vm.expectCall(PORTAL, setCalculatorCalldata);
    }

    /// @notice Executes the Safe transaction with proper signature handling
    /// @param safe The Safe contract instance
    /// @param owners Array of Safe owners
    /// @param txHash The transaction hash
    /// @param multicallData The multicall data
    function _executeSafeTransaction(
        IGnosisSafe safe,
        address[] memory owners,
        bytes32 txHash,
        bytes memory multicallData
    ) internal {
        // Prank owners to approve the hash
        for (uint256 i = 0; i < owners.length; i++) {
            vm.prank(owners[i]);
            safe.approveHash(txHash);
        }

        // Generate signatures after approval
        bytes memory signatures = Signatures.genPrevalidatedSignatures(owners);

        // Execute the transaction
        vm.prank(msg.sender); // Execute as current sender
        bool success = safe.execTransaction(
            template.multicallTarget(),
            0, // value
            multicallData,
            Enum.Operation.DelegateCall,
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            signatures
        );

        assertTrue(success, "Transaction should execute successfully");
    }

    function _verifyPortalCalls(Action[] memory actions, uint256 expectedDeploymentCalls) internal pure {
        uint256 expectedVaultsSetOperations = 12;
        uint256 expectedFeeSplitterSetOperations = 1;

        uint256 vaultsSetOperations;
        uint256 feeSplitterSetOperations;
        uint256 deploymentCalls;

        for (uint256 i = 0; i < actions.length; i++) {
            // Decode the depositTransaction parameters
            bytes memory params = new bytes(actions[i].arguments.length - 4);
            for (uint256 j = 0; j < params.length; j++) {
                params[j] = actions[i].arguments[j + 4];
            }
            (address to,,,,) = abi.decode(params, (address, uint256, uint64, bool, bytes));

            if (to == BASE_FEE_VAULT || to == SEQUENCER_FEE_VAULT || to == L1_FEE_VAULT || to == OPERATOR_FEE_VAULT) {
                vaultsSetOperations++;
            } else if (to == FEE_SPLITTER) {
                feeSplitterSetOperations++;
            } else if (to == CREATE2_DEPLOYER) {
                deploymentCalls++;
            } else {
                revert("Invalid target");
            }
        }
        assertEq(
            deploymentCalls,
            expectedDeploymentCalls,
            "expected deployment calls should match to actual calls made to portal"
        );

        assertEq(
            vaultsSetOperations,
            expectedVaultsSetOperations,
            "expected vaults set operations should match to actual calls made to portal"
        );
        assertEq(
            feeSplitterSetOperations,
            expectedFeeSplitterSetOperations,
            "expected fee splitter set operations should match to actual calls made to portal"
        );
    }

    function _expectVaultSetOperations(address[] memory _vaults, uint64 _gasLimit) internal {
        for (uint256 i = 0; i < _vaults.length; i++) {
            bytes memory setRecipientCalldata = abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (_vaults[i], 0, _gasLimit, false, abi.encodeCall(IFeeVault.setRecipient, (FEE_VAULT_RECIPIENT)))
            );

            vm.expectCall(PORTAL, setRecipientCalldata);
            bytes memory setMinWithdrawalAmountCalldata = abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    _vaults[i],
                    0,
                    _gasLimit,
                    false,
                    abi.encodeCall(IFeeVault.setMinWithdrawalAmount, (FEE_VAULT_MIN_WITHDRAWAL_AMOUNT))
                )
            );
            vm.expectCall(PORTAL, setMinWithdrawalAmountCalldata);
            bytes memory setWithdrawalNetworkCalldata = abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (
                    _vaults[i],
                    0,
                    _gasLimit,
                    false,
                    abi.encodeCall(IFeeVault.setWithdrawalNetwork, (FEE_VAULT_WITHDRAWAL_NETWORK))
                )
            );
            vm.expectCall(PORTAL, setWithdrawalNetworkCalldata);
        }
    }
}

/// @notice Test contract for the LateOptInRevenueShare that expect reverts on misconfiguration of required fields.
contract LateOptInRevenueShareRequiredFieldsTest is Test {
    LateOptInRevenueShare public template;

    function setUp() public {
        vm.createSelectFork("mainnet", 23197819);
        template = new LateOptInRevenueShare();
    }

    /// @notice Tests that the template reverts when using own calculator and the calculator address is zero.
    function test_lateOptInRevenueShare_calculator_zero_address_reverts() public {
        string memory configPath = "test/template/late-opt-in-rev-share/config/calculator-zero-address-config.toml";
        vm.expectRevert("calculator address must be set in config if opting to use own calculator");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when using default calculator and the salt seed is an empty string.
    function test_lateOptInRevenueShare_saltSeed_empty_string_reverts() public {
        string memory configPath = "test/template/late-opt-in-rev-share/config/salt-seed-empty-string-config.toml";
        vm.expectRevert("saltSeed must be set in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when using default calculator and the l1 withdrawer recipient is a zero address.
    function test_lateOptInRevenueShare_l1WithdrawerRecipient_zero_address_reverts() public {
        string memory configPath =
            "test/template/late-opt-in-rev-share/config/l1WithdrawerRecipient-zero-address-config.toml";
        vm.expectRevert("l1WithdrawerRecipient must be set in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when using default calculator and the l1 withdrawer gas limit is zero.
    function test_lateOptInRevenueShare_l1WithdrawerGasLimit_zero_reverts() public {
        string memory configPath = "test/template/late-opt-in-rev-share/config/l1WithdrawerGasLimit-zero-config.toml";
        vm.expectRevert("l1WithdrawerGasLimit must be greater than 0");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when using default calculator and the l1 withdrawer gas limit is too high.
    function test_lateOptInRevenueShare_l1WithdrawerGasLimit_too_high_reverts() public {
        string memory configPath =
            "test/template/late-opt-in-rev-share/config/l1WithdrawerGasLimit-too-high-config.toml";
        vm.expectRevert("l1WithdrawerGasLimit must be less than uint32.max");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when using default calculator and the chain fees recipient is a zero address.
    function test_lateOptInRevenueShare_scRevShareCalcChainFeesRecipient_zero_address_reverts() public {
        string memory configPath =
            "test/template/late-opt-in-rev-share/config/scRevShareCalcChainFeesRecipient-zero-address-config.toml";
        vm.expectRevert("scRevShareCalcChainFeesRecipient must be set in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the portal is a zero address.
    function test_lateOptInRevenueShare_portal_zero_address_reverts() public {
        string memory configPath = "test/template/late-opt-in-rev-share/config/portal-zero-address-config.toml";
        vm.expectRevert("SimpleAddressRegistry: zero address for OptimismPortal");
        template.simulate(configPath);
    }
}
