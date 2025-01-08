pragma solidity 0.8.15;

interface SystemConfig {
    function setGasLimit(uint64) external;

    function setGasConfig(uint256 _overhead, uint256 _scalar) external;

    function gasLimit() external view returns (uint64);

    function overhead() external view returns (uint256);

    function scalar() external view returns (uint256);
}
