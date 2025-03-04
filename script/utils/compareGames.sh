#!/bin/bash
set -euo pipefail

EXPECTED_ADDR=${1:?Must specify address of contract with expected values}
COMPARE_ADDR=${2:?Must specify address of contract to check}

function compare() {
  local A
  local B
  local CALL
  local A_VAL
  local B_VAL
  A=${1}
  B=${2}
  CALL=${3}
  A_VAL=$(cast call "${A}" "${CALL}")
  B_VAL=$(cast call "${B}" "${CALL}")
  if [ "${A_VAL}" != "${B_VAL}" ]
  then
    echo
    echo "Mismatch ${CALL}"
    echo "Was: ${A_VAL}"
    echo "Now: ${B_VAL}"
  else
    echo
    echo "Matches ${CALL} = ${A_VAL}"
  fi
}

compare "${EXPECTED_ADDR}" "${COMPARE_ADDR}" "version()(string)"
compare "${EXPECTED_ADDR}" "${COMPARE_ADDR}" "absolutePrestate()(bytes32)"
compare "${EXPECTED_ADDR}" "${COMPARE_ADDR}" "maxGameDepth()(uint256)"
compare "${EXPECTED_ADDR}" "${COMPARE_ADDR}" "splitDepth()(uint256)"
compare "${EXPECTED_ADDR}" "${COMPARE_ADDR}" "maxClockDuration()(uint256)"
compare "${EXPECTED_ADDR}" "${COMPARE_ADDR}" "gameType()(uint32)"
compare "${EXPECTED_ADDR}" "${COMPARE_ADDR}" "l2ChainId()(uint256)"
compare "${EXPECTED_ADDR}" "${COMPARE_ADDR}" "clockExtension()(uint64)"
compare "${EXPECTED_ADDR}" "${COMPARE_ADDR}" "anchorStateRegistry()(address)"

EXPECTED_WETH=$(cast call "${EXPECTED_ADDR}" "weth()(address)")
COMPARE_WETH=$(cast call "${COMPARE_ADDR}" "weth()(address)")

if [ "${EXPECTED_WETH}" == "${COMPARE_WETH}" ]
then
  echo "Matches weth()(address)"
else
  echo "Comparing WETH"
  compare "${EXPECTED_WETH}" "${COMPARE_WETH}" "version()(string)"
  compare "${EXPECTED_WETH}" "${COMPARE_WETH}" "delay()(uint256)"
  compare "${EXPECTED_WETH}" "${COMPARE_WETH}" "config()(address)"
fi

EXPECTED_VM=$(cast call "${EXPECTED_ADDR}" "vm()(address)")
COMPARE_VM=$(cast call "${COMPARE_ADDR}" "vm()(address)")
if [ "${EXPECTED_VM}" == "${COMPARE_VM}" ]
then
  echo "Matches vm()(address)"
else
  echo "Comparing vm"
  compare "${EXPECTED_VM}" "${COMPARE_VM}" "version()(string)"
fi
