// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {ProtocolVersions, ProtocolVersion} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "mainnet";
    string constant l2ChainName = "op";

    uint256 constant protoVerFjord = 0x0000000000000000000000000000000000000007000000000000000000000000;

    // Safe contract for this task.
    address foundationUpgradesSafe = vm.envAddress("FOUNDATION_SAFE");

    // All L1 proxy addresses.
    Types.ContractSet proxies;

    function setUp() public {
        proxies = _getContractSet();
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = foundationUpgradesSafe;
        allowed[1] = proxies.ProtocolVersions;
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running assertions");

        checkStateDiff(accesses);
        checkProtocolVersions();

        console.log("All assertions passed!");
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // No exceptions are expected in this task, but it must be implemented.
    }

    function checkProtocolVersions() internal view {
        console.log("Checking ProtocolVersions at ", proxies.ProtocolVersions);
        ProtocolVersions pv = ProtocolVersions(proxies.ProtocolVersions);
        require(pv.owner() == foundationUpgradesSafe, "PV owner must be Foundation Upgrade Safe");
        // We ignore the recommended version, as it is set by task#011
        require(ProtocolVersion.unwrap(pv.required()) == protoVerFjord, "Required PV must be Fjord");
    }

    /// @notice Reads the contract addresses from the superchain registry.
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory addressesJson;

        // Read superchain.yaml
        string[] memory inputs = new string[](4);
        inputs[0] = "yq";
        inputs[1] = "-o";
        inputs[2] = "json";
        inputs[3] = string.concat("lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.yaml");

        addressesJson = string(vm.ffi(inputs));

        _proxies.ProtocolVersions = stdJson.readAddress(addressesJson, "$.protocol_versions_addr");
    }

    function _addMultipleGenericOverrides()
        internal
        view
        override
        returns (SimulationStateOverride[] memory overrides_)
    {
        // set owner of ProtocolVersions to FUS (#011)
        bytes32 ownerSlot = 0x0000000000000000000000000000000000000000000000000000000000000033;
        overrides_ = new SimulationStateOverride[](1);
        overrides_[0].contractAddress = proxies.ProtocolVersions;
        overrides_[0].overrides = new SimulationStorageOverride[](1);
        overrides_[0].overrides[0] =
            SimulationStorageOverride({key: ownerSlot, value: bytes32(uint256(uint160(foundationUpgradesSafe)))});
    }
}
