// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/**
 * 数值没搞太懂，log有点没看明白
 * Solidity中的事件（event）是EVM上日志的抽象
 * 事件声明:由event关键字开头，接着是事件名称，括号里面写好事件需要记录的变量类型和变量名。
 */
contract Event {
    // ERC20代币合约的Transfer事件
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 定义_balances映射变量，记录每个地址的持币数量
    mapping(address => uint256) public _balances;

    // 定义_transfer函数，执行转账逻辑
    // 每次用_transfer()函数进行转账操作的时候，都会释放Transfer事件，并记录相应的变量。
    function _transfer(address from, address to, uint256 amount) external {
        _balances[from] = 10000000; // 给转账地址一些初始代币
        _balances[from] -=  amount; // from地址减去转账数量
        _balances[to] += amount; // to地址加上转账数量

        // 释放事件
        emit Transfer(from, to, amount);
    }
}