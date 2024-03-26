// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IGnosisSafe as Safe} from "@eth-optimism-bedrock/scripts/interfaces/IGnosisSafe.sol";

import {Simulator} from "@base-contracts/script/universal/Simulator.sol";

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {CommonBase} from "forge-std/Base.sol";

/// @title VmSplit
/// @dev Provides an interface supported by foundry but not yet in forge-std
interface VmSplit {
    function split(string memory _str, string memory _delim) external pure returns (string[] memory outputs_);
}

abstract contract JsonTxBuilderBase is Simulator {
    string json;

    function _loadJson(string memory _path) internal {
        console.log("Reading transaction bundle %s", _path);
        json = vm.readFile(_path);
    }

    function _getBasePath(string memory _path) internal pure returns (string memory) {
        string[] memory basePathArray = VmSplit(VM_ADDRESS).split(_path, "/");
        string memory basePath;
        for (uint256 i = 0; i < basePathArray.length - 1; i++) {
            basePath = string.concat(basePath, basePathArray[i], "/");
        }
        return basePath;
    }

    function _buildCallsFromJson() internal view returns (IMulticall3.Call3[] memory) {
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
            try vm.parseJsonAddress(json, string(abi.encodePacked("$.transactions[", vm.toString(i), "].to"))) returns (
                address
            ) {} catch {
                transaction_count = i;
            }
        }

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](transaction_count);

        for (uint256 i = 0; i < transaction_count; i++) {
            calls[i] = IMulticall3.Call3({
                target: stdJson.readAddress(json, string(abi.encodePacked("$.transactions[", vm.toString(i), "].to"))),
                allowFailure: false,
                callData: stdJson.readBytes(json, string(abi.encodePacked("$.transactions[", vm.toString(i), "].data")))
            });
        }

        return calls;
    }

    function _setLocalSimulationOverrides() internal {
        address ownerSafe = _ownerSafe();
        Simulator.SimulationStateOverride memory thresholdStateOverride =
            overrideSafeThresholdAndOwner(ownerSafe, address(this));
        Simulator.SimulationStorageOverride[] memory thresholdStorageOverrides = thresholdStateOverride.overrides;
        for (uint256 i = 0; i < thresholdStorageOverrides.length; i++) {
            Simulator.SimulationStorageOverride memory storageOverride = thresholdStorageOverrides[i];
            vm.store(thresholdStateOverride.contractAddress, storageOverride.key, storageOverride.value);
        }

        Simulator.SimulationStateOverride memory nonceStateOverride = overrideSafeThresholdAndNonce(ownerSafe, _nonce());
        Simulator.SimulationStorageOverride[] memory thresholdNonceOverrides = nonceStateOverride.overrides;
        for (uint256 i = 0; i < thresholdNonceOverrides.length; i++) {
            Simulator.SimulationStorageOverride memory storageOverride = thresholdNonceOverrides[i];
            vm.store(nonceStateOverride.contractAddress, storageOverride.key, storageOverride.value);
        }
    }

    function _ownerSafe() internal view virtual returns (address);

    function _nonce() internal view returns (uint256 nonce_) {
        nonce_ = Safe(_ownerSafe()).nonce();
        console.log("Safe current nonce:", nonce_);

        // workaround to check if the SAFE_NONCE env var is present
        try vm.envUint("SAFE_NONCE") {
            nonce_ = vm.envUint("SAFE_NONCE");
            console.log("Creating transaction with nonce:", nonce_);
        } catch {}
    }
}
