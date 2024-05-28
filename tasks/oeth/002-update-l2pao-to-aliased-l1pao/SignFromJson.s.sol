// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
}

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "mainnet";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe l2paoSafe = GnosisSafe(payable(0x7871d1187A97cbbE40710aC119AA3d412944e4Fe));

    IProxyAdmin l2pa = IProxyAdmin(Predeploys.PROXY_ADMIN);
    address constant unaliasedL1PAO = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A; // Aliased address on L2: 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b


    function checkL2PA() internal {
        console.log("Running assertions on the L2PA");
        address l2paOwner = l2pa.owner();
        require(
            l2paOwner == AddressAliasHelper.applyL1ToL2Alias(unaliasedL1PAO),
            "checkL2PA-100"
        );

        address payable l1Address = payable(
            AddressAliasHelper.undoL1ToL2Alias(l2paOwner)
        );
        uint256 originalFork = vm.activeFork();
        vm.createSelectFork(vm.envString("L1_ETH_RPC_URL")); // Forks on the latest block.

        require(l1Address.code.length > 0, "checkL2PA-200");
        require(
            GnosisSafe(payable(l1Address)).getThreshold() > 1,
            "checkL2PA-300"
        );

        vm.selectFork(originalFork);
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(
        Vm.AccountAccess[] memory accesses,
        SimulationPayload memory /* simPayload */
    ) internal override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkL2PA();

        console.log("All assertions passed!");
    }

    function getCodeExceptions()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory shouldHaveCodeExceptions = new address[](1);

        shouldHaveCodeExceptions[0] = AddressAliasHelper.applyL1ToL2Alias(
            unaliasedL1PAO
        ); // aliased L1PAO on op-sepolia doesn't have any code.

        return shouldHaveCodeExceptions;
    }
}
