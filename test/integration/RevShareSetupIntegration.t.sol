// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {RevShareContractsUpgrader} from "src/RevShareContractsUpgrader.sol";
import {RevShareSetup} from "src/template/RevShareSetup.sol";
import {IntegrationBase} from "./IntegrationBase.t.sol";
import {FeeVaultUpgrader} from "src/libraries/FeeVaultUpgrader.sol";
import {FeeSplitterSetup} from "src/libraries/FeeSplitterSetup.sol";
import {RevShareCommon} from "src/libraries/RevShareCommon.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";

contract RevShareSetupIntegrationTest is IntegrationBase {
    RevShareSetup public revShareTask;

    // EIP-1967 storage slots for proxy (specific to RevShareSetup test)
    bytes32 internal constant PROXY_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant PROXY_OWNER_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    // Creation codes from libraries (specific to RevShareSetup test)
    bytes internal OPERATOR_FEE_VAULT_CREATION_CODE = FeeVaultUpgrader.operatorFeeVaultCreationCode;
    bytes internal SEQUENCER_FEE_VAULT_CREATION_CODE = FeeVaultUpgrader.sequencerFeeVaultCreationCode;
    bytes internal DEFAULT_FEE_VAULT_CREATION_CODE = FeeVaultUpgrader.defaultFeeVaultCreationCode;
    bytes internal FEE_SPLITTER_CREATION_CODE = FeeSplitterSetup.feeSplitterCreationCode;

    function setUp() public {
        // Create forks for L1 (mainnet) and L2 (OP Mainnet)
        _mainnetForkId = vm.createFork("http://127.0.0.1:8545");
        _opMainnetForkId = vm.createFork("http://127.0.0.1:9545");
        _inkMainnetForkId = vm.createFork("http://127.0.0.1:9546");

        // Deploy contracts on L1
        vm.selectFork(_mainnetForkId);

        // Deploy RevShareContractsUpgrader and etch at predetermined address
        revShareUpgrader = new RevShareContractsUpgrader();
        vm.etch(REV_SHARE_UPGRADER_ADDRESS, address(revShareUpgrader).code);
        revShareUpgrader = RevShareContractsUpgrader(REV_SHARE_UPGRADER_ADDRESS);

        // Deploy RevShareSetup task
        revShareTask = new RevShareSetup();

        // Deploy implementations once to get their addresses and bytecode
        address operatorFeeVaultImpl = _deployFromCreationCode(OPERATOR_FEE_VAULT_CREATION_CODE);
        address sequencerFeeVaultImpl = _deployFromCreationCode(SEQUENCER_FEE_VAULT_CREATION_CODE);
        address defaultFeeVaultImpl = _deployFromCreationCode(DEFAULT_FEE_VAULT_CREATION_CODE);
        address feeSplitterImpl = _deployFromCreationCode(FEE_SPLITTER_CREATION_CODE);

        // Get implementation bytecodes
        bytes memory operatorFeeVaultImplCode = operatorFeeVaultImpl.code;
        bytes memory sequencerFeeVaultImplCode = sequencerFeeVaultImpl.code;
        bytes memory defaultFeeVaultImplCode = defaultFeeVaultImpl.code;
        bytes memory feeSplitterImplCode = feeSplitterImpl.code;

        // Deploy a proxy to get its bytecode
        Proxy proxyTemplate = new Proxy(address(this));
        bytes memory proxyCode = address(proxyTemplate).code;

        // Etch predeploys on OP Mainnet fork
        vm.selectFork(_opMainnetForkId);
        _etchImplementations(
            operatorFeeVaultImpl,
            sequencerFeeVaultImpl,
            defaultFeeVaultImpl,
            feeSplitterImpl,
            operatorFeeVaultImplCode,
            sequencerFeeVaultImplCode,
            defaultFeeVaultImplCode,
            feeSplitterImplCode
        );
        _setupProxyPredeploys(
            proxyCode, operatorFeeVaultImpl, sequencerFeeVaultImpl, defaultFeeVaultImpl, feeSplitterImpl
        );

        // Etch predeploys on Ink Mainnet fork
        vm.selectFork(_inkMainnetForkId);
        _etchImplementations(
            operatorFeeVaultImpl,
            sequencerFeeVaultImpl,
            defaultFeeVaultImpl,
            feeSplitterImpl,
            operatorFeeVaultImplCode,
            sequencerFeeVaultImplCode,
            defaultFeeVaultImplCode,
            feeSplitterImplCode
        );
        _setupProxyPredeploys(
            proxyCode, operatorFeeVaultImpl, sequencerFeeVaultImpl, defaultFeeVaultImpl, feeSplitterImpl
        );

        // Switch back to mainnet fork after setup
        vm.selectFork(_mainnetForkId);
    }

    /// @notice Deploy a contract from creation code
    /// @param _creationCode The creation code of the contract to deploy
    /// @return deployed The address of the deployed contract
    function _deployFromCreationCode(bytes memory _creationCode) internal returns (address deployed) {
        assembly {
            deployed := create(0, add(_creationCode, 0x20), mload(_creationCode))
        }
        require(deployed != address(0), "Deployment failed");
    }

    /// @notice Etch implementation bytecode at addresses on the current fork
    /// @param _operatorFeeVaultImpl OperatorFeeVault implementation address
    /// @param _sequencerFeeVaultImpl SequencerFeeVault implementation address
    /// @param _defaultFeeVaultImpl Default FeeVault implementation address
    /// @param _feeSplitterImpl FeeSplitter implementation address
    /// @param _operatorFeeVaultImplCode OperatorFeeVault implementation bytecode
    /// @param _sequencerFeeVaultImplCode SequencerFeeVault implementation bytecode
    /// @param _defaultFeeVaultImplCode Default FeeVault implementation bytecode
    /// @param _feeSplitterImplCode FeeSplitter implementation bytecode
    function _etchImplementations(
        address _operatorFeeVaultImpl,
        address _sequencerFeeVaultImpl,
        address _defaultFeeVaultImpl,
        address _feeSplitterImpl,
        bytes memory _operatorFeeVaultImplCode,
        bytes memory _sequencerFeeVaultImplCode,
        bytes memory _defaultFeeVaultImplCode,
        bytes memory _feeSplitterImplCode
    ) internal {
        vm.etch(_operatorFeeVaultImpl, _operatorFeeVaultImplCode);
        vm.etch(_sequencerFeeVaultImpl, _sequencerFeeVaultImplCode);
        vm.etch(_defaultFeeVaultImpl, _defaultFeeVaultImplCode);
        vm.etch(_feeSplitterImpl, _feeSplitterImplCode);
    }

    /// @notice Setup proxy predeploys pointing to implementations
    /// @param _proxyCode Proxy runtime bytecode
    /// @param _operatorFeeVaultImpl OperatorFeeVault implementation address
    /// @param _sequencerFeeVaultImpl SequencerFeeVault implementation address
    /// @param _defaultFeeVaultImpl Default FeeVault implementation address (for Base and L1)
    /// @param _feeSplitterImpl FeeSplitter implementation address
    function _setupProxyPredeploys(
        bytes memory _proxyCode,
        address _operatorFeeVaultImpl,
        address _sequencerFeeVaultImpl,
        address _defaultFeeVaultImpl,
        address _feeSplitterImpl
    ) internal {
        // Setup OperatorFeeVault proxy
        vm.etch(OPERATOR_FEE_VAULT, _proxyCode);
        vm.store(OPERATOR_FEE_VAULT, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(_operatorFeeVaultImpl))));
        vm.store(OPERATOR_FEE_VAULT, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));

        // Setup SequencerFeeVault proxy
        vm.etch(SEQUENCER_FEE_VAULT, _proxyCode);
        vm.store(SEQUENCER_FEE_VAULT, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(_sequencerFeeVaultImpl))));
        vm.store(SEQUENCER_FEE_VAULT, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));

        // Setup BaseFeeVault proxy
        vm.etch(BASE_FEE_VAULT, _proxyCode);
        vm.store(BASE_FEE_VAULT, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(_defaultFeeVaultImpl))));
        vm.store(BASE_FEE_VAULT, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));

        // Setup L1FeeVault proxy
        vm.etch(L1_FEE_VAULT, _proxyCode);
        vm.store(L1_FEE_VAULT, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(_defaultFeeVaultImpl))));
        vm.store(L1_FEE_VAULT, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));

        // Setup FeeSplitter proxy
        vm.etch(FEE_SPLITTER, _proxyCode);
        vm.store(FEE_SPLITTER, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(_feeSplitterImpl))));
        vm.store(FEE_SPLITTER, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));
    }

    /// @notice Test the integration of setupRevShare
    function test_setupRevShare_integration() public {
        // Step 1: Record logs for L1→L2 message replay
        vm.recordLogs();

        // Step 2: Execute task simulation
        revShareTask.simulate("test/tasks/example/eth/017-revshare-setup/config.toml");

        // Step 3: Relay deposit transactions from L1 to all L2s
        uint256[] memory forkIds = new uint256[](2);
        forkIds[0] = _opMainnetForkId;
        forkIds[1] = _inkMainnetForkId;

        address[] memory portals = new address[](2);
        portals[0] = OP_MAINNET_PORTAL;
        portals[1] = INK_MAINNET_PORTAL;

        _relayAllMessages(forkIds, IS_SIMULATE, portals);

        // Step 4: Assert the state of the OP Mainnet contracts
        vm.selectFork(_opMainnetForkId);
        _assertL2State(
            OP_L1_WITHDRAWER,
            OP_REV_SHARE_CALCULATOR,
            OP_MIN_WITHDRAWAL_AMOUNT,
            OP_L1_WITHDRAWAL_RECIPIENT,
            OP_WITHDRAWAL_GAS_LIMIT,
            OP_CHAIN_FEES_RECIPIENT
        );

        // Step 5: Assert the state of the Ink Mainnet contracts
        vm.selectFork(_inkMainnetForkId);
        _assertL2State(
            INK_L1_WITHDRAWER,
            INK_REV_SHARE_CALCULATOR,
            INK_MIN_WITHDRAWAL_AMOUNT,
            INK_L1_WITHDRAWAL_RECIPIENT,
            INK_WITHDRAWAL_GAS_LIMIT,
            INK_CHAIN_FEES_RECIPIENT
        );

        // Step 6: Do a withdrawal flow

        // Fund vaults with amount > minWithdrawalAmount
        _fundVaults(1 ether, _opMainnetForkId);
        _fundVaults(1 ether, _inkMainnetForkId);

        // Disburse fees in both chains and expect the L1Withdrawer to trigger the withdrawal
        // Expected L1Withdrawer share = 3 ether * 15% = 0.45 ether
        // It is 3 ether instead of 4 because net revenue doesn't count L1FeeVault's balance
        // For details on the rev share calculation, check the SuperchainRevSharesCalculator contract.
        // https://github.com/ethereum-optimism/optimism/blob/f392d4b7e8bc5d1c8d38fcf19c8848764f8bee3b/packages/contracts-bedrock/src/L2/SuperchainRevSharesCalculator.sol#L67-L101
        uint256 expectedWithdrawalAmount = 0.45 ether;

        _executeDisburseAndAssertWithdrawal(_opMainnetForkId, OP_L1_WITHDRAWAL_RECIPIENT, expectedWithdrawalAmount);
        _executeDisburseAndAssertWithdrawal(_inkMainnetForkId, INK_L1_WITHDRAWAL_RECIPIENT, expectedWithdrawalAmount);
    }
}
