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

    // Implementation addresses (deployed and etched in setUp)
    address internal _operatorFeeVaultImpl;
    address internal _sequencerFeeVaultImpl;
    address internal _defaultFeeVaultImpl;
    address internal _feeSplitterImpl;

    function setUp() public {
        // Create forks for L1 (mainnet) and L2 (OP Mainnet only - proxies already upgraded)
        _mainnetForkId = vm.createFork("http://127.0.0.1:8545");
        _opMainnetForkId = vm.createFork("http://127.0.0.1:9545");

        // Deploy contracts on L1
        vm.selectFork(_mainnetForkId);

        // Deploy RevShareContractsUpgrader and etch at predetermined address
        revShareUpgrader = new RevShareContractsUpgrader();
        vm.etch(REV_SHARE_UPGRADER_ADDRESS, address(revShareUpgrader).code);
        revShareUpgrader = RevShareContractsUpgrader(REV_SHARE_UPGRADER_ADDRESS);

        // Deploy RevShareSetup task
        revShareTask = new RevShareSetup();

        // Deploy implementations once to get their addresses and bytecode
        _operatorFeeVaultImpl = _deployFromCreationCode(OPERATOR_FEE_VAULT_CREATION_CODE);
        _sequencerFeeVaultImpl = _deployFromCreationCode(SEQUENCER_FEE_VAULT_CREATION_CODE);
        _defaultFeeVaultImpl = _deployFromCreationCode(DEFAULT_FEE_VAULT_CREATION_CODE);
        _feeSplitterImpl = _deployFromCreationCode(FEE_SPLITTER_CREATION_CODE);

        // Get implementation bytecodes
        bytes memory operatorFeeVaultImplCode = _operatorFeeVaultImpl.code;
        bytes memory sequencerFeeVaultImplCode = _sequencerFeeVaultImpl.code;
        bytes memory defaultFeeVaultImplCode = _defaultFeeVaultImpl.code;
        bytes memory feeSplitterImplCode = _feeSplitterImpl.code;

        // Deploy a proxy to get its bytecode
        Proxy proxyTemplate = new Proxy(address(this));
        bytes memory proxyCode = address(proxyTemplate).code;

        // Etch predeploys on OP Mainnet fork (proxies already upgraded, just need setup)
        vm.selectFork(_opMainnetForkId);
        _etchImplementations(
            _operatorFeeVaultImpl,
            _sequencerFeeVaultImpl,
            _defaultFeeVaultImpl,
            _feeSplitterImpl,
            operatorFeeVaultImplCode,
            sequencerFeeVaultImplCode,
            defaultFeeVaultImplCode,
            feeSplitterImplCode
        );
        _setupProxyPredeploys(
            proxyCode, _operatorFeeVaultImpl, _sequencerFeeVaultImpl, _defaultFeeVaultImpl, _feeSplitterImpl
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
    /// @param operatorFeeVaultImplAddr OperatorFeeVault implementation address
    /// @param sequencerFeeVaultImplAddr SequencerFeeVault implementation address
    /// @param defaultFeeVaultImplAddr Default FeeVault implementation address
    /// @param feeSplitterImplAddr FeeSplitter implementation address
    /// @param operatorFeeVaultImplCode OperatorFeeVault implementation bytecode
    /// @param sequencerFeeVaultImplCode SequencerFeeVault implementation bytecode
    /// @param defaultFeeVaultImplCode Default FeeVault implementation bytecode
    /// @param feeSplitterImplCode FeeSplitter implementation bytecode
    function _etchImplementations(
        address operatorFeeVaultImplAddr,
        address sequencerFeeVaultImplAddr,
        address defaultFeeVaultImplAddr,
        address feeSplitterImplAddr,
        bytes memory operatorFeeVaultImplCode,
        bytes memory sequencerFeeVaultImplCode,
        bytes memory defaultFeeVaultImplCode,
        bytes memory feeSplitterImplCode
    ) internal {
        vm.etch(operatorFeeVaultImplAddr, operatorFeeVaultImplCode);
        vm.etch(sequencerFeeVaultImplAddr, sequencerFeeVaultImplCode);
        vm.etch(defaultFeeVaultImplAddr, defaultFeeVaultImplCode);
        vm.etch(feeSplitterImplAddr, feeSplitterImplCode);
    }

    /// @notice Setup proxy predeploys pointing to implementations
    /// @param proxyCode Proxy runtime bytecode
    /// @param operatorFeeVaultImplAddr OperatorFeeVault implementation address
    /// @param sequencerFeeVaultImplAddr SequencerFeeVault implementation address
    /// @param defaultFeeVaultImplAddr Default FeeVault implementation address (for Base and L1)
    /// @param feeSplitterImplAddr FeeSplitter implementation address
    function _setupProxyPredeploys(
        bytes memory proxyCode,
        address operatorFeeVaultImplAddr,
        address sequencerFeeVaultImplAddr,
        address defaultFeeVaultImplAddr,
        address feeSplitterImplAddr
    ) internal {
        // Setup OperatorFeeVault proxy
        vm.etch(OPERATOR_FEE_VAULT, proxyCode);
        vm.store(OPERATOR_FEE_VAULT, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(operatorFeeVaultImplAddr))));
        vm.store(OPERATOR_FEE_VAULT, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));

        // Setup SequencerFeeVault proxy
        vm.etch(SEQUENCER_FEE_VAULT, proxyCode);
        vm.store(SEQUENCER_FEE_VAULT, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(sequencerFeeVaultImplAddr))));
        vm.store(SEQUENCER_FEE_VAULT, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));

        // Setup BaseFeeVault proxy
        vm.etch(BASE_FEE_VAULT, proxyCode);
        vm.store(BASE_FEE_VAULT, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(defaultFeeVaultImplAddr))));
        vm.store(BASE_FEE_VAULT, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));

        // Setup L1FeeVault proxy
        vm.etch(L1_FEE_VAULT, proxyCode);
        vm.store(L1_FEE_VAULT, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(defaultFeeVaultImplAddr))));
        vm.store(L1_FEE_VAULT, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));

        // Setup FeeSplitter proxy
        vm.etch(FEE_SPLITTER, proxyCode);
        vm.store(FEE_SPLITTER, PROXY_IMPLEMENTATION_SLOT, bytes32(uint256(uint160(feeSplitterImplAddr))));
        vm.store(FEE_SPLITTER, PROXY_OWNER_SLOT, bytes32(uint256(uint160(RevShareCommon.PROXY_ADMIN))));
    }

    /// @notice Test the integration of setupRevShare (OP Mainnet only - proxies already upgraded)
    function test_setupRevShare_integration() public {
        // Step 1: Record logs for L1→L2 message replay
        vm.recordLogs();

        // Step 2: Execute task simulation
        revShareTask.simulate("test/tasks/example/eth/016-revshare-setup/config.toml");

        // Step 3: Relay deposit transactions from L1 to OP Mainnet
        uint256[] memory forkIds = new uint256[](1);
        forkIds[0] = _opMainnetForkId;

        address[] memory portals = new address[](1);
        portals[0] = OP_MAINNET_PORTAL;

        _relayAllMessages(forkIds, IS_SIMULATE, portals);

        // Step 4: Assert the state of the OP Mainnet contracts
        vm.selectFork(_opMainnetForkId);
        address opL1Withdrawer =
            _computeL1WithdrawerAddress(OP_MIN_WITHDRAWAL_AMOUNT, OP_L1_WITHDRAWAL_RECIPIENT, OP_WITHDRAWAL_GAS_LIMIT);
        address opRevShareCalculator = _computeRevShareCalculatorAddress(opL1Withdrawer, OP_CHAIN_FEES_RECIPIENT);
        _assertL2State(
            opL1Withdrawer,
            opRevShareCalculator,
            OP_MIN_WITHDRAWAL_AMOUNT,
            OP_L1_WITHDRAWAL_RECIPIENT,
            OP_WITHDRAWAL_GAS_LIMIT,
            OP_CHAIN_FEES_RECIPIENT
        );

        // Step 5: Do a withdrawal flow

        // Fund vaults with amount > minWithdrawalAmount
        // It disburses 5 ether to each of the 4 vaults, so total sent is 20 ether
        _fundVaults(5 ether, _opMainnetForkId);

        // Disburse fees and expect the L1Withdrawer to trigger the withdrawal
        // Expected L1Withdrawer share = 15 ether * 15% = 2.25 ether
        // It is 15 ether instead of 20 because net revenue doesn't count L1FeeVault's balance
        // For details on the rev share calculation, check the SuperchainRevSharesCalculator contract.
        // https://github.com/ethereum-optimism/optimism/blob/f392d4b7e8bc5d1c8d38fcf19c8848764f8bee3b/packages/contracts-bedrock/src/L2/SuperchainRevSharesCalculator.sol#L67-L101
        uint256 expectedWithdrawalAmount = 2.25 ether;

        _executeDisburseAndAssertWithdrawal(_opMainnetForkId, OP_L1_WITHDRAWAL_RECIPIENT, expectedWithdrawalAmount);
    }
}
