// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";

/// @notice Interface for the OptimismPortal2 contract on L1.
interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

/// @notice Template to execute an L2 call via the L1 Optimism Portal from a nested L1 Safe.
/// Sends an L2 transaction using OptimismPortal.depositTransaction with config-driven params.
/// Supports: op-contracts/v4.6.0
contract L1PortalExecuteL2Call is L2TaskBase {
    using stdToml for string;

    // -------- Config inputs --------
    /// @notice The address of the L2 target contract.
    address public l2Target;
    /// @notice The calldata to be executed on l2Target.
    bytes public l2Data;
    /// @notice The L2 gas limit.
    uint64 public gasLimit;
    /// @notice Whether to create a contract on L2.
    bool public isCreation;

    /// @notice Default Safe name. Can be overridden via `safeAddressString` in config.toml.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice The contracts expected to have storage writes during execution.
    /// Allowlist the OptimismPortal since it will mutate state (queue/event) on deposit.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory _storageWrites = new string[](1);
        _storageWrites[0] = "OptimismPortalProxy";
        return _storageWrites;
    }

    /// @notice The contracts expected to have balance changes during execution.
    function _taskBalanceChanges() internal pure override returns (string[] memory) {}

    /// @notice Parse config and initialize template variables.
    /// Expected TOML keys:
    /// - l2Target: address (L2 target address)
    /// - l2Data: hex string (e.g. 0x1234...)
    /// - gasLimit: uint (will be cast to uint64)
    /// - isCreation: bool (optional, default false)
    function _templateSetup(string memory _taskConfigFilePath, address) internal override {
        string memory _toml = vm.readFile(_taskConfigFilePath);

        // Read hex string and parse to bytes.
        l2Data = _toml.readBytes(".l2Data");
        require(l2Data.length > 0, "l2Data must be set");
        require(l2Data.length <= 120000, "l2Data exceeds max message size");

        uint256 _gasLimitTmp = _toml.readUint(".gasLimit");
        require(_gasLimitTmp >= 21000 && _gasLimitTmp <= type(uint64).max, "gasLimit out of valid range");
        gasLimit = uint64(_gasLimitTmp);

        // Optional fields
        isCreation = false;
        try vm.parseTomlBool(_toml, ".isCreation") returns (bool _b) {
            isCreation = _b;
        } catch {}

        // Validate target address based on operation type
        l2Target = _toml.readAddress(".l2Target");
        if (isCreation) {
            require(l2Target == address(0), "contract creation requires zero target address");
        } else {
            require(l2Target != address(0), "regular call requires non-zero target address");
        }
    }

    /// @notice Build the portal deposit action. WARNING: State changes here are reverted after capture.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 _i = 0; _i < chains.length; _i++) {
            IOptimismPortal2(superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[_i].chainId))
                .depositTransaction(l2Target, 0, gasLimit, isCreation, l2Data);
        }
    }

    /// @notice Validate that exactly one action to the portal with the expected calldata was captured.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal view override {
        bytes memory _expected =
            abi.encodeCall(IOptimismPortal2.depositTransaction, (l2Target, 0, gasLimit, isCreation, l2Data));

        bool _found;
        uint256 _matches;
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 _i = 0; _i < chains.length; _i++) {
            for (uint256 _j = 0; _j < _actions.length; _j++) {
                if (
                    _actions[_j].target == superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[_i].chainId)
                        && _actions[_j].value == 0
                ) {
                    if (keccak256(_actions[_j].arguments) == keccak256(_expected)) {
                        _found = true;
                        _matches++;
                    }
                }
            }
        }

        require(_found && _matches == chains.length, "expected one portal deposit action for each chain");
        MultisigTaskPrinter.printTitle("Validated portal deposit action");
    }

    /// @notice No code exceptions required for this template.
    function _getCodeExceptions() internal view override returns (address[] memory) {}
}
