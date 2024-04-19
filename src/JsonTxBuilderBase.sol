// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {CommonBase} from "forge-std/Base.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

abstract contract JsonTxBuilderBase is CommonBase {
    string json;

    function _loadJson(string memory _path) internal {
        console.log("Reading transaction bundle %s", _path);
        json = vm.readFile(_path);
    }

    function _buildCallsFromJson() internal view returns (IMulticall3.Call3[] memory) {
        return _buildCallsFromJson(json);
    }

    function _buildCallsFromJson(string memory jsonContent) internal pure returns (IMulticall3.Call3[] memory) {
        // A hacky way to get the total number of elements in a JSON
        // object array because Forge does not support this natively.
        uint256 MAX_LENGTH_SUPPORTED = 999;
        uint256 transaction_count = MAX_LENGTH_SUPPORTED;
        for (uint256 i = 0; transaction_count == MAX_LENGTH_SUPPORTED; i++) {
            require(
                i < MAX_LENGTH_SUPPORTED,
                "Transaction list longer than MAX_LENGTH_SUPPORTED is not "
                "supported, to support it, simply bump the value of " "MAX_LENGTH_SUPPORTED to a bigger one."
            );
            try vm.parseJsonAddress(jsonContent, string(abi.encodePacked("$.transactions[", vm.toString(i), "].to")))
            returns (address) {} catch {
                transaction_count = i;
            }
        }

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](transaction_count);

        for (uint256 i = 0; i < transaction_count; i++) {
            calls[i] = IMulticall3.Call3({
                target: stdJson.readAddress(
                    jsonContent, string(abi.encodePacked("$.transactions[", vm.toString(i), "].to"))
                ),
                allowFailure: false,
                callData: stdJson.readBytes(
                    jsonContent, string(abi.encodePacked("$.transactions[", vm.toString(i), "].data"))
                )
            });
        }

        return calls;
    }

    /// @notice Reads all account and storage accesses and makes a series of basic sanity checks on them.
    ///         This function can be overridden to provide more specific checks, but should still call
    ///         super.checkStateDiff().
    function checkStateDiff(Vm.AccountAccess[] memory accountAccesses) internal view virtual {
        console.log("Running assertions on the state diff");
        require(accountAccesses.length > 0, "No account accesses");

        for (uint256 i; i < accountAccesses.length; i++) {
            Vm.AccountAccess memory accountAccess = accountAccesses[i];

            // All touched accounts should have code, with the exception of precompiles.
            if (!isPrecompile(accountAccess.account)) {
                require(
                    accountAccess.account.code.length != 0,
                    string.concat("Account has no code: ", vm.toString(accountAccess.account))
                );
            }

            require(
                accountAccess.oldBalance == accountAccess.account.balance,
                string.concat("Unexpected balance change: ", vm.toString(accountAccess.account))
            );
            require(
                accountAccess.kind != VmSafe.AccountAccessKind.SelfDestruct,
                string.concat("Self-destructed account: ", vm.toString(accountAccess.account))
            );

            for (uint256 j; j < accountAccess.storageAccesses.length; j++) {
                Vm.StorageAccess memory storageAccess = accountAccess.storageAccesses[j];

                if (!storageAccess.isWrite) continue; // Skip SLOADs.

                uint256 value = uint256(storageAccess.newValue);
                if (isLikelyAddressThatShouldHaveCode(value)) {
                    // Log account, slot, and value if there is no code.
                    string memory err = string.concat(
                        "Likely address in storage has no code\n",
                        "  account: ",
                        vm.toString(storageAccess.account),
                        "\n  slot:    ",
                        vm.toString(storageAccess.slot),
                        "\n  value:   ",
                        vm.toString(bytes32(value))
                    );
                    require(address(uint160(value)).code.length != 0, err);
                } else {
                    // Log account, slot, and value if there is code.
                    string memory err = string.concat(
                        "Likely address in storage has unexpected code\n",
                        "  account: ",
                        vm.toString(storageAccess.account),
                        "\n  slot:    ",
                        vm.toString(storageAccess.slot),
                        "\n  value:   ",
                        vm.toString(bytes32(value))
                    );
                    require(address(uint160(value)).code.length == 0, err);
                }

                require(
                    storageAccess.account.code.length != 0,
                    string.concat("Storage account has no code: ", vm.toString(storageAccess.account))
                );
                require(
                    !storageAccess.reverted,
                    string.concat("Storage access reverted: ", vm.toString(storageAccess.account))
                );
                require(
                    storageAccess.account.code.length != 0,
                    string.concat("Storage account has no code: ", vm.toString(storageAccess.account))
                );
                require(
                    !storageAccess.reverted,
                    string.concat("Storage access reverted: ", vm.toString(storageAccess.account))
                );
            }
        }
    }

    /// @notice Returns a list of addresses which are expected to be in storage, but will not to have code on this
    ///         chain. Examples of such addresses include EOAs, predeploy addresses, and inbox addresses.
    function getCodeExceptions() internal pure virtual returns (address[] memory exceptions) {
        exceptions; // Named return and this no-op required to silence compiler warnings.
        require(false, "getCodeExceptions not implemented");
    }

    /// @notice Checks that values have code on this chain.
    ///         This method is not storage-layout-aware and therefore is not perfect. It may return erroneous
    ///         results for cases like packed slots, and silently show that things are okay when they are not.
    function isLikelyAddressThatShouldHaveCode(uint256 value) internal view virtual returns (bool) {
        // If out of range (fairly arbitrary lower bound), return false.
        if (value > type(uint160).max) return false;
        if (value < uint256(uint160(0x00000000fFFFffffffFfFfFFffFfFffFFFfFffff))) return false;

        // If the value is a L2 predeploy address it won't have code on this chain, so return false.
        if (
            value >= uint256(uint160(0x4200000000000000000000000000000000000000))
                && value <= uint256(uint160(0x420000000000000000000000000000000000FffF))
        ) return false;

        // Allow known EOAs.
        address[] memory exceptions = getCodeExceptions();
        for (uint256 i; i < exceptions.length; i++) {
            if (address(uint160(value)) == exceptions[i]) return false;
        }

        // Otherwise, this value looks like an address that we'd expect to have code.
        return true;
    }

    /// @notice Returns true if the address is a precompile, false otherwise.
    function isPrecompile(address addr) internal pure returns (bool) {
        return addr >= address(0x1) && addr <= address(0xa);
    }
}
