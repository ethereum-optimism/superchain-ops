// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {IOptimismPortal2} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOptimismPortal2.sol";
import {MultisigTaskPrinter} from "../../libraries/MultisigTaskPrinter.sol";
import {Action} from "../../libraries/MultisigTypes.sol";
import {SimpleTaskBase} from "../tasks/types/SimpleTaskBase.sol";

/// @notice Template to execute an L2 call via the L1 Optimism Portal from a nested L1 Safe.
/// Sends an L2 transaction using OptimismPortal.depositTransaction with config-driven params.
contract L1PortalExecuteL2Call is SimpleTaskBase {
    using stdToml for string;

    // -------- Config inputs --------
    address payable public portal; // L1 OptimismPortal address
    address public l2Target; // L2 target address
    bytes public l2Data; // Inner L2 calldata
    uint256 public valueWei; // ETH value to forward to L2 (defaults to 0)
    uint64 public gasLimit; // L2 gas limit (required)
    bool public isCreation; // Whether to create a contract on L2 (defaults to false)

    /// @notice Default Safe name. Can be overridden via `safeAddressString` in config.toml.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice The contracts expected to have storage writes during execution.
    /// Allowlist the OptimismPortal since it will mutate state (queue/event) on deposit.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory _storageWrites = new string[](1);
        _storageWrites[0] = "OptimismPortal";
        return _storageWrites;
    }

    /// @notice The contracts expected to have balance changes during execution.
    /// Allowlist the OptimismPortal to receive ETH (value) in the deposit call.
    function _taskBalanceChanges() internal pure override returns (string[] memory) {
        string[] memory _balanceChanges = new string[](1);
        _balanceChanges[0] = "OptimismPortal";
        return _balanceChanges;
    }

    /// @notice Parse config and initialize template variables.
    /// Expected TOML keys:
    /// - portal: address (L1 OptimismPortal) OR addresses.OptimismPortal in [addresses]
    /// - l2Target: address (L2 target address)
    /// - l2Data: hex string (e.g. 0x1234...)
    /// - gasLimit: uint (will be cast to uint64)
    /// - value: uint (optional, default 0)
    /// - isCreation: bool (optional, default false)
    function _templateSetup(string memory _taskConfigFilePath, address) internal override {
        string memory _toml = vm.readFile(_taskConfigFilePath);

        // Resolve portal from registry first if available, else read explicit field.
        try simpleAddrRegistry.get("OptimismPortal") returns (address p) {
            portal = payable(p);
        } catch {
            portal = payable(_toml.readAddress(".portal"));
        }
        require(portal != address(0), "portal must be set (addresses.OptimismPortal or .portal)");

        l2Target = _toml.readAddress(".l2Target");
        require(l2Target != address(0), "l2Target must be set");

        // Read hex string and parse to bytes.
        string memory _dataHex = _toml.readString(".l2Data");
        l2Data = vm.parseBytes(_dataHex);
        require(l2Data.length > 0, "l2Data must be set");

        uint256 _gasLimitTmp = _toml.readUint(".gasLimit");
        require(_gasLimitTmp > 0 && _gasLimitTmp <= type(uint64).max, "invalid gasLimit");
        gasLimit = uint64(_gasLimitTmp);

        // Optional fields
        valueWei = 0;
        try vm.parseTomlUint(_toml, ".value") returns (uint256 _v) {
            valueWei = _v;
        } catch {}

        isCreation = false;
        try vm.parseTomlBool(_toml, ".isCreation") returns (bool _b) {
            isCreation = _b;
        } catch {}
    }

    /// @notice Build the portal deposit action. WARNING: State changes here are reverted after capture.
    function _build(address) internal override {
        // Record the L1 portal call with value for action extraction.
        IOptimismPortal2(portal).depositTransaction{value: valueWei}(l2Target, valueWei, gasLimit, isCreation, l2Data);
    }

    /// @notice Validate that exactly one action to the portal with the expected calldata and value was captured.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal view override {
        bytes memory _expected = abi.encodeWithSelector(
            IOptimismPortal2.depositTransaction.selector, l2Target, valueWei, gasLimit, isCreation, l2Data
        );

        bool _found;
        uint256 _matches;
        for (uint256 _i = 0; _i < _actions.length; _i++) {
            if (_actions[_i].target == portal && _actions[_i].value == valueWei) {
                if (keccak256(_actions[_i].arguments) == keccak256(_expected)) {
                    _found = true;
                    _matches++;
                }
            }
        }
        require(_found && _matches == 1, "expected one portal deposit action");
        MultisigTaskPrinter.printTitle("Validated portal deposit action");
    }

    /// @notice No code exceptions required for this template.
    function _getCodeExceptions() internal view override returns (address[] memory) {}
}
