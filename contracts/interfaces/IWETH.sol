pragma solidity 0.6.12;

interface IWETH {
    function balanceOf(address user) external view returns (uint256);
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}