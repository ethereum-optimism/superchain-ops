#!/bin/bash
set -eo pipefail

# ---------------------------------------------
# Test script for check-struct-order.sh
#
# Creates temporary Solidity files with various struct patterns
# and verifies the check script correctly identifies:
# - Structs with alphabetically ordered fields (should pass)
# - Structs with non-alphabetically ordered fields (should fail)
#
# Usage: Run from any directory inside the git repo.
# ---------------------------------------------

# Get the repo root and script directories
repo_root="$(git rev-parse --show-toplevel)"
src_script_dir="$repo_root/src/script"

echo "Running check-struct-order.sh tests..."
echo ""

# Track test results
tests_passed=0
tests_failed=0

# Track temp directories for cleanup
temp_dirs=""

# shellcheck disable=SC2317,SC2329  # cleanup is called via trap
cleanup() {
    for dir in $temp_dirs; do
        [ -d "$dir" ] && rm -rf "$dir"
    done
}
trap cleanup EXIT

# Helper function to run a test case
# Args: $1 = test name, $2 = expected result (pass|fail), $3 = file content
run_test() {
    local test_name=$1
    local expected=$2
    local content=$3

    # Create a fresh temp directory for this test
    local test_dir
    test_dir=$(mktemp -d)
    temp_dirs="$temp_dirs $test_dir"

    # Create test file
    local test_file="$test_dir/src/template/Test${test_name}.sol"
    mkdir -p "$(dirname "$test_file")"
    echo "$content" > "$test_file"

    # Initialize git repo
    (cd "$test_dir" && git init -q) > /dev/null 2>&1

    # Run the check script from the test directory
    local result
    if (cd "$test_dir" && "$src_script_dir/check-struct-order.sh") > /dev/null 2>&1; then
        result="pass"
    else
        result="fail"
    fi

    # Check result
    if [ "$result" = "$expected" ]; then
        echo "  PASS: $test_name (expected $expected, got $result)"
        tests_passed=$((tests_passed + 1))
    else
        echo "  FAIL: $test_name (expected $expected, got $result)"
        tests_failed=$((tests_failed + 1))
    fi
}

echo "=== Test Cases ==="
echo ""

# Test 1: Alphabetically ordered struct (should pass)
run_test "AlphabeticalOrder" "pass" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdToml} from "forge-std/StdToml.sol";

contract TestAlphabeticalOrder {
    using stdToml for string;

    struct Config {
        address addr;
        uint256 chainId;
        string name;
    }

    function setup(string memory toml) internal {
        Config[] memory configs = abi.decode(toml.parseRaw(".configs"), (Config[]));
    }
}
'

# Test 2: Non-alphabetically ordered struct (should fail)
run_test "NonAlphabeticalOrder" "fail" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdToml} from "forge-std/StdToml.sol";

contract TestNonAlphabeticalOrder {
    using stdToml for string;

    struct Config {
        string name;
        address addr;
        uint256 chainId;
    }

    function setup(string memory toml) internal {
        Config[] memory configs = abi.decode(toml.parseRaw(".configs"), (Config[]));
    }
}
'

# Test 3: Primitive array (should pass - no struct to check)
run_test "PrimitiveArray" "pass" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdToml} from "forge-std/StdToml.sol";

contract TestPrimitiveArray {
    using stdToml for string;

    function setup(string memory toml) internal {
        address[] memory addrs = abi.decode(toml.parseRaw(".addresses"), (address[]));
        uint256[] memory ids = abi.decode(toml.parseRaw(".ids"), (uint256[]));
    }
}
'

# Test 4: Single struct (not array) - alphabetical (should pass)
run_test "SingleStructAlphabetical" "pass" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

contract TestSingleStructAlphabetical {
    VmSafe internal constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct Settings {
        bool enabled;
        uint256 value;
    }

    function setup(string memory toml) internal {
        Settings memory s = abi.decode(vm.parseToml(toml, ".settings"), (Settings));
    }
}
'

# Test 5: Similar field name prefixes - wrong order (should fail)
# This is the exact bug pattern from OPCMUpgradeV600
run_test "SimilarPrefixes" "fail" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdToml} from "forge-std/StdToml.sol";

contract TestSimilarPrefixes {
    using stdToml for string;

    struct Prestate {
        bytes32 cannonPrestate;
        bytes32 cannonKonaPrestate;
    }

    function setup(string memory toml) internal {
        Prestate[] memory p = abi.decode(toml.parseRaw(".prestates"), (Prestate[]));
    }
}
'

# Test 6: Similar prefixes but correct order (should pass)
run_test "SimilarPrefixesCorrect" "pass" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdToml} from "forge-std/StdToml.sol";

contract TestSimilarPrefixesCorrect {
    using stdToml for string;

    struct Prestate {
        bytes32 cannonKonaPrestate;
        bytes32 cannonPrestate;
    }

    function setup(string memory toml) internal {
        Prestate[] memory p = abi.decode(toml.parseRaw(".prestates"), (Prestate[]));
    }
}
'

# Test 7: No parseRaw usage (should pass - nothing to check)
run_test "NoParseRaw" "pass" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract TestNoParseRaw {
    struct Config {
        string name;
        address addr;
    }

    function doSomething() internal pure returns (uint256) {
        return 42;
    }
}
'

# Test 8: Complex types in struct (should pass if alphabetical)
run_test "ComplexTypes" "pass" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdToml} from "forge-std/StdToml.sol";

contract TestComplexTypes {
    using stdToml for string;

    struct GameConfig {
        address[] addresses;
        bytes32 gameType;
        uint256[] values;
    }

    function setup(string memory toml) internal {
        GameConfig[] memory configs = abi.decode(toml.parseRaw(".games"), (GameConfig[]));
    }
}
'

# Test 9: JSON with stdJson.parseRaw - wrong order (should fail)
run_test "JsonWrongOrder" "fail" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdJson} from "forge-std/StdJson.sol";

contract TestJsonWrongOrder {
    using stdJson for string;

    struct JsonConfig {
        string name;
        address addr;
    }

    function setup(string memory json) internal {
        JsonConfig[] memory configs = abi.decode(json.parseRaw(".configs"), (JsonConfig[]));
    }
}
'

# Test 10: JSON with vm.parseJson - correct order (should pass)
run_test "JsonCorrectOrder" "pass" '
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";

contract TestJsonCorrectOrder {
    VmSafe internal constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct JsonConfig {
        address addr;
        string name;
    }

    function setup(string memory json) internal {
        JsonConfig memory config = abi.decode(vm.parseJson(json, ".config"), (JsonConfig));
    }
}
'

echo ""
echo "=== Summary ==="
echo "Passed: $tests_passed"
echo "Failed: $tests_failed"
echo ""

if [ $tests_failed -gt 0 ]; then
    echo "Some tests failed!"
    exit 1
else
    echo "All tests passed!"
    exit 0
fi
