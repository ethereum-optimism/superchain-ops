pragma solidity 0.8.15;

library BytesHelper {
    /// @notice function to grab the first 32 bytes of returned memory
    /// @param toSlice the calldata payload
    function getFirstWord(bytes memory toSlice) public pure returns (uint256 value) {
        require(toSlice.length >= 32, "Length less than 32 bytes");

        assembly ("memory-safe") {
            value := mload(add(toSlice, 0x20))
        }
    }
}
