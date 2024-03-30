// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson} from "../../../script/SignFromJson.s.sol";

contract PostCheck is SignFromJson {
    function _postCheck() internal view override {}
}
