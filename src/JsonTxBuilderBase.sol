// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {CommonBase} from "forge-std/Base.sol";


abstract contract JsonTxBuilderBase is CommonBase {
    string json;

    function _loadJson(string memory _path) internal {
        console.log("Reading transaction bundle %s", _path);
        try vm.readFile(_path) returns (string memory data) {
            json = data;
        } catch {
            console.log("Error: unable to transaction bundle.");
            return;
        }
    }

    function _buildCallsFromJson() internal view returns (IMulticall3.Call3[] memory) {
        // A hacky way to get the total number of elements in a JSON
        // object array because Forge does not support this natively.
        uint MAX_LENGTH_SUPPORTED = 999;
        uint transaction_count = MAX_LENGTH_SUPPORTED;
        for(uint i = 0; transaction_count == MAX_LENGTH_SUPPORTED; i++) {
            require(i < MAX_LENGTH_SUPPORTED,
                    "Transaction list longer than MAX_LENGTH_SUPPORTED is not "
                    "supported, to support it, simply bump the value of "
                    "MAX_LENGTH_SUPPORTED to a bigger one.");
            try vm.parseJsonAddress(json, string(abi.encodePacked("$.transactions[", vm.toString(i), "].to"))) returns (address) {
            } catch {
                transaction_count = i;
            }
        }

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](transaction_count);

        for (uint i = 0; i < transaction_count; i++) {
            calls[i] = IMulticall3.Call3({
                target: stdJson.readAddress(json, string(abi.encodePacked("$.transactions[", vm.toString(i), "].to"))),
                allowFailure: false,
                callData: stdJson.readBytes(json, string(abi.encodePacked("$.transactions[", vm.toString(i), "].data")))
                });
        }

        return calls;
    }
}
