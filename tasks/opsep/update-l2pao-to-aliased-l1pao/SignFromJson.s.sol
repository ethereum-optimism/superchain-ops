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
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe l2paoSafe = GnosisSafe(payable(0xb41890910b05dCba3d3dEF19B27E886C4Ab406EB));

    IProxyAdmin l2pa = IProxyAdmin(Predeploys.PROXY_ADMIN);
    address constant unaliasedL1PAO = 0x1Eb2fFc903729a0F03966B917003800b145F56E2;

    function setUp() public {}

    function checkL2PA() internal view {
        console.log("Running assertions on the L2PA");
        address l2paOwner = l2pa.owner();
        require(l2paOwner == AddressAliasHelper.applyL1ToL2Alias(unaliasedL1PAO), "checkL2PA-100");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkL2PA();

        console.log("All assertions passed!");
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory shouldHaveCodeExceptions = new address[](1);

        shouldHaveCodeExceptions[0] = AddressAliasHelper.applyL1ToL2Alias(unaliasedL1PAO); // aliased L1PAO on op-sepolia doesn't have any code.

        return shouldHaveCodeExceptions;
    }
}
