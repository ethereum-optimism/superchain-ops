// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
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

    uint256 constant scalarFjord = 0x010000000000000000000000000000000000000000000000000f79c50000146b;

    // Safe contract for this task.
    address foundationUpgradesSafe = vm.envAddress("OWNER_SAFE");

    // All L1 proxy addresses.
    Types.ContractSet proxies;

    function setUp() public {
        proxies = _getContractSet();
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = foundationUpgradesSafe;
        allowed[1] = proxies.SystemConfig;
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running assertions");

        checkStateDiff(accesses);
        checkSystemConfig();

        console.log("All assertions passed!");
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // No exceptions are expected in this task, but it must be implemented.
    }

    function checkSystemConfig() internal view {
        console.log("Checking SystemConfig at ", proxies.SystemConfig);
        SystemConfig sc = SystemConfig(proxies.SystemConfig);
        require(sc.owner() == address(foundationUpgradesSafe), "SC owner must be Foundation Upgrade Safe");
        require(sc.overhead() == 0, "SC overhead should still be 0");
        require(sc.scalar() == scalarFjord, "SC wrong encoded scalar value");
    }

    /// @notice Reads the contract addresses from the superchain registry.
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory addressesJson;

        addressesJson = vm.readFile(
            string.concat("lib/superchain-registry/superchain/extra/addresses/", l1ChainName, "/", l2ChainName, ".json")
        );
        _proxies.SystemConfig = stdJson.readAddress(addressesJson, "$.SystemConfigProxy");
    }

    function _addMultipleGenericOverrides()
        internal
        view
        override
        returns (SimulationStateOverride[] memory overrides_)
    {
        // set owner of SystemConfig to FUS (#011)
        bytes32 ownerSlot = 0x0000000000000000000000000000000000000000000000000000000000000033;
        overrides_ = new SimulationStateOverride[](1);
        overrides_[0].contractAddress = proxies.SystemConfig;
        overrides_[0].overrides = new SimulationStorageOverride[](1);
        overrides_[0].overrides[0] =
            SimulationStorageOverride({key: ownerSlot, value: bytes32(uint256(uint160(foundationUpgradesSafe)))});
    }
}
