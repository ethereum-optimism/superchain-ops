// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

import {SimpleTaskBase} from "src/improvements/tasks/types/SimpleTaskBase.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";

/// TODO: If you need any interfaces from the Optimism monorepo submodule. Define them here instead of importing them.
/// Doing this avoids tight coupling to the monorepo submodule and allows you to update the monorepo submodule
/// without having to update the template (Remove this comment when done).

/// @notice A template contract for configuring SimpleTaskBase templates.
/// Supports: <TODO: add supported tags: e.g. op-contracts/v*.*.*>
contract SimpleTaskBaseTemplate is SimpleTaskBase {
    using LibString for string;
    using SafeERC20 for IERC20;
    using stdToml for string;

    /// @notice Example variable to be used in the task.
    uint256 public exampleVariable = 0;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        require(false, "TODO: Implement with the correct safe address string.");
        return "";
    }

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        require(false, "TODO: Implement with the correct storage writes.");
        return new string[](0);
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        simpleAddrRegistry;
        require(false, "TODO: Implement with the correct template setup.");
    }

    /// @notice Before implementing the `_build` function, template developers must consider the following:
    /// 1. Which Multicall contract does this template use — `Multicall3` or `Multicall3Delegatecall`?
    /// 2. Based on the contract, should the target be called using `call` or `delegatecall`?
    /// 3. Ensure that the call to the target uses the appropriate method (`call` or `delegatecall`) accordingly.
    /// Guidelines:
    /// - `Multicall3`:
    ///  If the template directlyinherits from `L2TaskBase` or `SimpleTaskBase`, it uses the `Multicall3` contract.
    ///  In this case, calls to the target **must** use `call`, e.g.:
    ///  ` dgm.setRespectedGameType(IOptimismPortal2(payable(portalAddress)), cfg[chainId].gameType);`
    function _build() internal override {
        simpleAddrRegistry;
        exampleVariable = 1;
        require(false, "TODO: Implement with the correct build logic.");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal pure override {
        require(false, "TODO: Implement with the correct validation logic.");
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        require(
            false, "TODO: Implement the logic to return a list of addresses that should not be checked for code length."
        );
        return new address[](0);
    }
}
