#!/bin/bash
set -eo pipefail

# ---------------------------------------------
# Script to detect structs used with TOML/JSON parseRaw that have
# non-alphabetically ordered fields.
#
# When Foundry's parseRaw() converts TOML/JSON to ABI-encoded bytes,
# it orders struct fields ALPHABETICALLY by key name. If the Solidity
# struct fields are not in alphabetical order, abi.decode() will
# assign values to the wrong fields. See:
# https://getfoundry.sh/reference/cheatcodes/parse-toml/#decoding-toml-tables-into-solidity-structs
#
# This script:
# 1. Finds all abi.decode() calls with parseRaw/parseToml/parseJson
# 2. Extracts the struct type being decoded into
# 3. Finds the struct definition
# 4. Verifies fields are in alphabetical order
#
# Usage: Run from any directory inside the git repo.
# ---------------------------------------------

# Get the root directory of the git repo
root_dir=$(git rev-parse --show-toplevel)
src_dir="$root_dir/src"
exit_code=0

# Colors for output (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Primitive types to skip - these don't have named fields, so alphabetical
# ordering doesn't apply. Only structs with named fields can have the bug.
# Example: abi.decode(..., (address[])) is safe, but abi.decode(..., (MyStruct[])) needs checking.
# Pattern matches: address, bool, string, bytes, uint8-uint256, int8-int256, bytes1-bytes32
PRIMITIVE_TYPES="address|bool|string|bytes|uint[0-9]+|int[0-9]+|bytes[0-9]+"

# Function to extract struct field names from a file
# Args: $1 = file path, $2 = struct name
# Returns: newline-separated field names
extract_struct_fields() {
    local file=$1
    local struct_name=$2

    # Use awk to extract the struct body (handles indented closing brace)
    # Then grep for field declarations: <type> <name>; or <type>[] <name>;
    awk "/struct ${struct_name} \\{/,/^[[:space:]]*\\}/" "$file" 2>/dev/null | \
        grep -E '^[[:space:]]+[A-Za-z][A-Za-z0-9_]*(\[\])?[[:space:]]+[a-z][A-Za-z0-9_]*;' | \
        awk '{print $2}' | \
        sed 's/;//g'
}

# Function to find struct definition file
# Args: $1 = struct name, $2 = starting file (to check first)
# Returns: file path containing the struct, or empty if not found
find_struct_file() {
    local struct_name=$1
    local start_file=$2

    # First check the starting file
    if grep -q "struct ${struct_name} {" "$start_file" 2>/dev/null; then
        echo "$start_file"
        return
    fi

    # Search in common locations
    local found_file
    found_file=$(grep -rl "struct ${struct_name} {" "$src_dir" 2>/dev/null | head -1)

    if [ -n "$found_file" ]; then
        echo "$found_file"
    fi
}

# Function to check if fields are alphabetically ordered
# Args: field names via stdin (newline-separated)
# Returns: 0 if ordered, 1 if not
check_alphabetical_order() {
    local fields
    fields=$(cat)

    if [ -z "$fields" ]; then
        return 0  # Empty is considered ordered
    fi

    local sorted
    sorted=$(echo "$fields" | sort)

    if [ "$fields" = "$sorted" ]; then
        return 0
    else
        return 1
    fi
}

# Function to extract struct type from abi.decode line
# Args: $1 = line containing abi.decode
# Returns: struct type name or empty if primitive/not found
extract_struct_type() {
    local line=$1

    # Extract the type from patterns like:
    # abi.decode(..., (StructName[]))
    # abi.decode(..., (StructName))
    local type_match

    # Try to match (TypeName[]) or (TypeName) at the end
    type_match=$(echo "$line" | sed -E 's/.*\(([A-Z][A-Za-z0-9_]+)(\[\])?\)\s*\)\s*;.*/\1/' 2>/dev/null)

    # Check if we got a valid type (starts with uppercase, not a primitive)
    if [ -n "$type_match" ] && [ "$type_match" != "$line" ]; then
        # Skip primitive types
        if echo "$type_match" | grep -qE "^(${PRIMITIVE_TYPES})$"; then
            return
        fi
        echo "$type_match"
    fi
}

echo "Checking TOML/JSON struct field ordering..."
echo ""

# Find all files with abi.decode + parseRaw/parseToml/parseJson patterns
# Using a temp file for portability (process substitution behavior varies)
temp_file=$(mktemp)
checked_file=$(mktemp)
trap 'rm -f "$temp_file" "$checked_file"' EXIT

grep -rn "abi\.decode.*\(parseRaw\|\.parseRaw\|vm\.parseToml\|vm\.parseJson\)" \
    --include="*.sol" "$src_dir" 2>/dev/null > "$temp_file" || true

if [ ! -s "$temp_file" ]; then
    echo "No TOML/JSON struct parsing patterns found."
    exit 0
fi

while IFS= read -r match; do
    # Parse the grep output: file:line:content
    file=$(echo "$match" | cut -d: -f1)
    line_num=$(echo "$match" | cut -d: -f2)
    line_content=$(echo "$match" | cut -d: -f3-)

    # Extract struct type
    struct_type=$(extract_struct_type "$line_content")

    if [ -z "$struct_type" ]; then
        continue  # Skip primitives or unparseable lines
    fi

    # Find the struct definition file
    struct_file=$(find_struct_file "$struct_type" "$file")

    if [ -z "$struct_file" ]; then
        echo -e "${YELLOW}Warning: Could not find struct '$struct_type' (used in $file:$line_num)${NC}"
        continue
    fi

    # Create a unique key for this struct+file combination
    check_key="${struct_type}:${struct_file}"

    # Skip if we've already checked this combination (use grep on temp file)
    if grep -qF "$check_key" "$checked_file" 2>/dev/null; then
        continue
    fi
    echo "$check_key" >> "$checked_file"

    # Extract and check field ordering
    fields=$(extract_struct_fields "$struct_file" "$struct_type")

    if [ -z "$fields" ]; then
        echo -e "${YELLOW}Warning: Could not extract fields from struct '$struct_type' in $struct_file${NC}"
        continue
    fi

    if echo "$fields" | check_alphabetical_order; then
        echo -e "${GREEN}OK${NC} $struct_type (in ${struct_file#"$root_dir"/})"
    else
        echo -e "${RED}FAIL${NC} $struct_type (in ${struct_file#"$root_dir"/})"
        echo "  Fields are not in alphabetical order!"
        echo "  Current order:  $(echo "$fields" | tr '\n' ' ')"
        echo "  Expected order: $(echo "$fields" | sort | tr '\n' ' ')"
        echo ""
        exit_code=1
    fi
done < "$temp_file"

echo ""
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}All TOML/JSON-parsed structs have correctly ordered fields.${NC}"
else
    echo -e "${RED}[FAIL] Some structs have incorrectly ordered fields! See above for details.${NC}"
    echo ""
    echo "To fix: Reorder the struct fields to be in alphabetical order."
    echo "This is required because Foundry's parseRaw()/parseToml()/parseJson()"
    echo "orders keys alphabetically when converting to ABI-encoded bytes."
    echo ""
    echo "See: https://getfoundry.sh/reference/cheatcodes/parse-toml/#decoding-toml-tables-into-solidity-structs"
fi

exit $exit_code
