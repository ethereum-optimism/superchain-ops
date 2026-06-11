// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {Base64} from "solady/utils/Base64.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

/// @notice Tests the Tenderly Simulator "draft" link builder. Tenderly's current Simulator URL format
/// encodes the whole simulation as a base64url JSON payload in a `?draft=` query parameter.
/// @dev All assertions that depend on `TENDERLY_GAS` live in a single test function. Foundry executes
/// test functions concurrently and `vm.setEnv` mutates the shared process environment, so the only
/// race-safe pattern is to set the env and use it back-to-back within one function (the same pattern
/// `TaskManagerUnitTest.testSetTenderlyGasEnv` relies on).
contract TenderlySimulationLinkTest is Test {
    address internal constant TO = 0xcA11bde05977b3631167028862bE2a173976CA11;
    address internal constant FROM = 0x5aAdFB43eF8dAF45DD80F4676345b7676f1D70e3;
    address internal constant OVERRIDE_ADDR = 0x1Eb2fFc903729a0F03966B917003800b145F56E2;
    bytes32 internal constant OVERRIDE_KEY = bytes32(uint256(0x4));
    bytes32 internal constant OVERRIDE_VALUE = bytes32(uint256(0x1));

    function setUp() public {
        vm.chainId(11155111);
    }

    function _overrides() internal pure returns (Simulation.StateOverride[] memory overrides) {
        Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](1);
        storageOverrides[0] = Simulation.StorageOverride({key: OVERRIDE_KEY, value: OVERRIDE_VALUE});
        overrides = new Simulation.StateOverride[](1);
        overrides[0] = Simulation.StateOverride({contractAddress: OVERRIDE_ADDR, overrides: storageOverrides});
    }

    function _setTenderlyEnv(string memory gas) internal {
        vm.setEnv("TENDERLY_USERNAME", "oplabs");
        vm.setEnv("TENDERLY_PROJECT", "op-sepolia");
        vm.setEnv("TENDERLY_GAS", gas);
    }

    function _expectedUrl(string memory row) internal view returns (string memory) {
        string memory payload =
            string.concat("{\"v\":1,\"network\":{\"id\":\"", vm.toString(block.chainid), "\"},\"row\":", row, "}");
        return string.concat(
            "https://dashboard.tenderly.co/oplabs/op-sepolia/simulator/new?draft=",
            Base64.encode(bytes(payload), true, true)
        );
    }

    function _stateOverridesJson() internal pure returns (string memory) {
        return string.concat(
            "\"stateOverrides\":[{\"contractAddress\":\"",
            vm.toString(OVERRIDE_ADDR),
            "\",\"balance\":\"\",\"storage\":[{\"key\":\"",
            vm.toString(OVERRIDE_KEY),
            "\",\"value\":\"",
            vm.toString(OVERRIDE_VALUE),
            "\"}]}]}"
        );
    }

    /// @notice Exercises every branch of the builder back-to-back in one function so the shared
    /// `TENDERLY_GAS` environment variable cannot be clobbered by a concurrently-running test.
    function test_getTenderlySimulationLink() public {
        bytes memory data = hex"a9059cbb";

        // 1. Full draft: network, contract, from, raw calldata, gas, and state overrides all embedded.
        _setTenderlyEnv("15000000");
        string memory link = MultisigTaskPrinter.getTenderlySimulationLink(TO, data, FROM, _overrides(), true);
        string memory expectedRow = string.concat(
            "{\"contractAddress\":\"",
            vm.toString(TO),
            "\",\"from\":\"",
            vm.toString(FROM),
            "\",\"inputDataType\":\"raw\",\"rawFunctionInput\":\"",
            vm.toString(data),
            "\",\"gas\":\"15000000\",",
            _stateOverridesJson()
        );
        assertEq(link, _expectedUrl(expectedRow));

        // 2. Fallback: `rawFunctionInput` omitted -> strictly shorter link, everything else preserved.
        string memory linkNoInput = MultisigTaskPrinter.getTenderlySimulationLink(TO, data, FROM, _overrides(), false);
        string memory expectedRowNoInput = string.concat(
            "{\"contractAddress\":\"",
            vm.toString(TO),
            "\",\"from\":\"",
            vm.toString(FROM),
            "\",\"inputDataType\":\"raw\",\"gas\":\"15000000\",",
            _stateOverridesJson()
        );
        assertEq(linkNoInput, _expectedUrl(expectedRowNoInput));
        assertLt(bytes(linkNoInput).length, bytes(link).length);

        // 3. No gas configured: the `gas` field is omitted entirely.
        _setTenderlyEnv("");
        string memory linkNoGas =
            MultisigTaskPrinter.getTenderlySimulationLink(TO, data, FROM, new Simulation.StateOverride[](0), true);
        string memory expectedRowNoGas = string.concat(
            "{\"contractAddress\":\"",
            vm.toString(TO),
            "\",\"from\":\"",
            vm.toString(FROM),
            "\",\"inputDataType\":\"raw\",\"rawFunctionInput\":\"",
            vm.toString(data),
            "\",\"stateOverrides\":[]}"
        );
        assertEq(linkNoGas, _expectedUrl(expectedRowNoGas));
    }

    /// @notice The new format must use `?draft=` and not the old `?network=...&stateOverrides=...` params.
    function test_getTenderlySimulationLink_usesDraftFormat() public {
        _setTenderlyEnv("15000000");
        string memory link = MultisigTaskPrinter.getTenderlySimulationLink(TO, hex"a9059cbb", FROM, _overrides(), true);
        assertTrue(vm.contains(link, "/simulator/new?draft="));
        assertFalse(vm.contains(link, "network="));
        assertFalse(vm.contains(link, "stateOverrides=%5B"));
    }
}
