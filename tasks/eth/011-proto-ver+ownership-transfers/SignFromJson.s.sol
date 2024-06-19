// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {ProtocolVersions, ProtocolVersion} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {L1StandardBridge} from "@eth-optimism-bedrock/src/L1/L1StandardBridge.sol";
import {L2OutputOracle} from "@eth-optimism-bedrock/src/L1/L2OutputOracle.sol";
import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
import {OptimismPortal} from "@eth-optimism-bedrock/src/L1/OptimismPortal.sol";
import {L1CrossDomainMessenger} from "@eth-optimism-bedrock/src/L1/L1CrossDomainMessenger.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/src/L1/L1ERC721Bridge.sol";
import {AddressManager} from "@eth-optimism-bedrock/src/legacy/AddressManager.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "mainnet";
    string constant l2ChainName = "op";

    uint256 constant protoVerEcotone = 0x0000000000000000000000000000000000000006000000000000000000000000;
    uint256 constant protoVerFjord = 0x0000000000000000000000000000000000000007000000000000000000000000;

    // Safe contract for this task.
    GnosisSafe foundationUpgradesSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe foundationOperationsSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_OP_SAFE")));

    // All L1 proxy addresses.
    Types.ContractSet proxies;

    function setUp() public {
        proxies = _getContractSet();
    }

    function checkStateDiff(Vm.AccountAccess[] memory accountAccesses) internal view override {
        address[] memory allowed = new address[](2);
        allowed[0] = address(foundationOperationsSafe);
        allowed[1] = proxies.ProtocolVersions;
        // TODO: add SuperchainConfig once that's in the bundle
        super.checkStateDiff(accountAccesses, allowed);

        checkProtocolVersions();
        // TODO: also check superchain config ownership transfer
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running assertions");

        checkStateDiff(accesses);

        console.log("All assertions passed!");
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // No exceptions are expected in this task, but it must be implemented.
    }

    function checkProtocolVersions() internal view {
        ProtocolVersions pv = ProtocolVersions(proxies.ProtocolVersions);
        // TODO: uncomment once owner transfer is implemented.
        //require(pv.owner() == address(foundationUpgradesSafe), "PV owner must be Foundation Upgrade Safe");
        require(ProtocolVersion.unwrap(pv.recommended()) == protoVerFjord, "Recommended PV must be Fjord");
        require(ProtocolVersion.unwrap(pv.required()) == protoVerEcotone, "Required PV must still be Ecotone");
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
        _proxies.SuperchainConfig = stdJson.readAddress(addressesJson, "$.superchain_config_addr");
    }
}
