// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";


contract SignFromJson is OriginalSignFromJson {

    /// @notice Sets up the contract
    function setUp() public {
    }


    /// @notice Checks the correctness of the deployment
    function _postCheck()
        internal
        view
    {
        // console.log("Running post-deploy assertions");
        // console.log("All assertions passed!");
    }

   
}
