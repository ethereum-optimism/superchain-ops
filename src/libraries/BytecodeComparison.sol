// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import {LibString} from "@solady/utils/LibString.sol";

/// @title BytecodeComparison
/// @notice Library for comparing bytecode of two contracts.
library BytecodeComparison {
    struct Diff {
        uint256 start;
        bytes content;
    }

    /// @notice Compares the bytecode for two contracts.
    /// @param _contractA Address of the first contract.
    /// @param _contractB Address of the second contract.
    /// @param _allowed List of allowed diffs.
    /// @return True if no diffs are found.
    function compare(address _contractA, address _contractB, Diff[] memory _allowed) internal view returns (bool) {
        return compare(_contractA.code, _contractB.code, _allowed);
    }

    /// @notice Compares the bytecode for two contracts.
    /// @param _bytecodeA Bytecode of the first contract.
    /// @param _bytecodeB Bytecode of the second contract.
    /// @param _allowed List of allowed diffs.
    /// @return True if no diffs are found.
    function compare(bytes memory _bytecodeA, bytes memory _bytecodeB, Diff[] memory _allowed)
        internal
        pure
        returns (bool)
    {
        if (_bytecodeA.length != _bytecodeB.length) {
            revert("BytecodeComparison: diff in bytecode length");
        }

        for (uint256 i = 0; i < _bytecodeA.length; i++) {
            if (_bytecodeA[i] != _bytecodeB[i]) {
                bool isAllowedDiff = false;

                // Check if this index falls within any allowed diff ranges
                for (uint256 a = 0; a < _allowed.length; a++) {
                    uint256 diffEnd = _allowed[a].start + _allowed[a].content.length;
                    if (i >= _allowed[a].start && i < diffEnd) {
                        // Check if the byte matches the expected diff content
                        if (_bytecodeB[i] == _allowed[a].content[i - _allowed[a].start]) {
                            isAllowedDiff = true;
                            break;
                        }
                    }
                }

                if (!isAllowedDiff) {
                    revert(
                        string.concat(
                            "BytecodeComparison: unexpected diff found at index:",
                            LibString.toString(i),
                            ", byte:",
                            LibString.toHexString(abi.encodePacked(_bytecodeB[i]))
                        )
                    );
                }
            }
        }

        return true;
    }
}
