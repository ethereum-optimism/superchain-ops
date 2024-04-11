// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Simulator} from "@base-contracts/script/universal/Simulator.sol";
import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";

contract EOASignFromJson is Simulator, JsonTxBuilderBase {
    function run(string memory _path) public {
        _loadJson(_path);
        IMulticall3.Call3[] memory calls = _buildCalls();
        (Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) = _execute(calls);
        _postCheck(accesses, simPayload);

    }

    function _buildCalls() internal view returns (IMulticall3.Call3[] memory) {
        return _buildCallsFromJson();
    }

    function _execute(IMulticall3.Call3[] memory calls) internal returns (Vm.AccountAccess[] memory, SimulationPayload memory) {
        address proxyAdminOwner = vm.envOr("PROXY_ADMIN_OWNER", address(0));
        require(proxyAdminOwner != address(0), "EOASignFromJson::_execute: PROXY_ADMIN_OWNER not set");

        vm.startStateDiffRecording();
        vm.startBroadcast(proxyAdminOwner);

        for (uint256 i = 0; i < calls.length; i++) {
            address target = calls[i].target;
            bytes memory data = calls[i].callData;

            (bool ok, bytes memory returnData) = target.call(data);
            require(ok, _executionRevertString(i, calls[i], returnData));
        }

        vm.stopBroadcast();
        Vm.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();

        // In reality we cannot execute this transaction bundle atomically (i.e. in a single
        // transaction) since it's coming from an EOA. To simulate this for analysis of the state
        // diff in e.g. Tenderly, you can place the Multicall3 code at the `msg.sender` address to
        // allow batching all calls into one for simulation purposes. We then have a dummy
        // recognizable `from` address call into `msg.sender` to execute the transaction batch. This
        // SimulationPayload does not log any state overrides because the struct definition does not
        // support code overrides. So instead, just execute the following command to obtain the
        // Multicall3 bytecode and make sure to place that code at the `msg.sender` address:
        //     cast code 0xcA11bde05977b3631167028862bE2a173976CA11 -r $MAINNET_RPC_URL
        SimulationPayload memory simPayload = SimulationPayload({
            from: 0x1234567812345678123456781234567812345678,
            to: msg.sender,
            data: abi.encode(calls),
            stateOverrides: new SimulationStateOverride[](0)
        });

        return (accesses, simPayload);

    }

    function _executionRevertString(uint256 index, IMulticall3.Call3 memory call, bytes memory revertData)
        internal
        view
        returns (string memory)
    {
        return string.concat(
            "EOASignFromJson::_execute: call failed at index ",
            vm.toString(index),
            "\n  from:       ",
            vm.toString(msg.sender),
            "\n  to:         ",
            vm.toString(call.target),
            "\n  calldata:   ",
            vm.toString(call.callData),
            "\n  revertData: ",
            vm.toString(revertData)
        );
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload) internal view virtual {
        accesses; // Silences compiler warnings.
        simPayload;
        require(false, "EOASignFromJson::_postCheck not implemented"); // Force user to implement post-check assertions.
    }
}
