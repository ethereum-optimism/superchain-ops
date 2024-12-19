// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {ProtocolVersions, ProtocolVersion} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "mainnet";
    string constant l2ChainName = "op";

    uint256 constant protoVerHolocene = 0x0000000000000000000000000000000000000009000000000000000000000000;

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
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
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
        // We ignore the recommended version, as it is set by this task
        require(ProtocolVersion.unwrap(pv.required()) == protoVerHolocene, "Required PV must be Holocene");
        require(ProtocolVersion.unwrap(pv.recommended()) == protoVerHolocene, "Required PV must be Holocene");
    }

    /// @notice Reads the contract addresses from the superchain registry.
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory chainConfig;
        string memory path =
            string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        _proxies.ProtocolVersions = stdToml.readAddress(chainConfig, "$.protocol_versions_addr");
    }

    function _addMultipleGenericOverrides() internal view returns (Simulation.StateOverride[] memory overrides_) {
        // set owner of ProtocolVersions to FUS
        bytes32 ownerSlot = 0x0000000000000000000000000000000000000000000000000000000000000033;
        overrides_ = new Simulation.StateOverride[](1);
        overrides_[0].contractAddress = proxies.ProtocolVersions;
        overrides_[0].overrides = new Simulation.StorageOverride[](1);
        overrides_[0].overrides[0] =
            Simulation.StorageOverride({key: ownerSlot, value: bytes32(uint256(uint160(foundationUpgradesSafe)))});
    }
}
