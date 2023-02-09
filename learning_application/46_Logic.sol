// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 逻辑合约，被调用方
contract Logic {
    // 与Proxy保持一致，防止插槽冲突
    address public implementation;
    uint public x = 99;
    // 调用成功事件
    event CallSuccess();

    // 这个函数会释放CallSuccess事件并返回一个uint。
    // 函数selector: 0xd09de08a
    function increment() external returns(uint) {
        emit CallSuccess();
        return x + 1;
    }
}