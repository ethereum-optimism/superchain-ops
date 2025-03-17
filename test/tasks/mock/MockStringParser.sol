pragma solidity 0.8.15;

import {StringParser} from "src/libraries/StringParser.sol";

/// @notice mock contract for testing StringParser library
contract MockStringParser {
    function parseDecimals(string memory amount) external pure returns (uint256, uint8) {
        return StringParser.parseDecimals(amount);
    }

    function parseAmountComponents(string memory amount) external pure returns (StringParser.AmountComponents memory components) {
        return StringParser.parseAmountComponents(amount);
    }

    function validateAmountFormat(string[] memory components) external pure {
        StringParser.validateAmountFormat(components);
    }
}