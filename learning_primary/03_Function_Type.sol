// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Function_Type{
    uint256 public number = 5;

    constructor() payable {}

    // 函数类型
    // function (<parameter types>) {internal|external} [pure|view|payable] [returns (<return types>)]

    // Default:rw
    function add() external {
        number = number + 1;
    }

    // Pure:--
    function addPure(uint256 _number) external pure returns(uint256 result) {
        result = _number + 1;
    }

    // View:r-
    function addView() external view returns(uint256 result) {
        result = number + 1;
    }

    // internal:只能从合约内部访问，继承的合约可以用。
    function minus() internal {
        number = number - 1;
    }

    function minusCall() external {
        minus();
    }

    function minusPayable() external payable returns(uint256 result) {
        minus();
        result = address(this).balance;
    }
}