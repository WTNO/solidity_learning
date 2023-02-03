// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * delegatecall 和 call 区别
 * 1.delegatecall在调用合约时可以指定交易发送的gas，但不能指定发送的ETH数额
 * 2.第二点有点类似前端的转发和重定向？
 * 不同，应该说是调用别人的方法，改变的数据是自身的状态变量（调用者和被调用者的状态变量和定义顺序需要相同（貌似有关））
 *
 * PS：delegatecall有安全隐患，使用时要保证《当前合约》和《目标合约》的《状态变量存储结构》相同，
 *     并且目标合约安全，不然会造成资产损失。
 * 
 * 使用场景
 * 1.代理合约:将智能合约的存储合约和逻辑合约分开，代理合约（Proxy Contract）存储所有相关的变量，并且保存逻辑合约的地址；
 *           所有函数存在逻辑合约（Logic Contract）里，通过delegatecall执行。当升级时，只需要将代理合约指向新的逻辑合约即可。
 * 2.EIP-2535 Diamonds（钻石）:钻石是一个支持构建可在生产中扩展的模块化智能合约系统的标准。钻石是具有多个实施合同的代理合同。
 */
contract Delegatecall {
    
}

// 代理合约
contract B {
    uint public num;
    address public sender;

    // 使用call调用合约C的setVars函数，改变的是合约C中的状态变量num
    function callSetVars(address _address, uint256 _num) public payable {
        (bool success, bytes memory data) = _address.call(abi.encodeWithSignature("setVars(uint256)", _num));
    }

    // 使用call调用合约C的setVars函数，改变的是合约C中的状态变量num
    function delegatecallSetVars(address _address, uint256 _num) public payable {
        (bool success, bytes memory data) = _address.delegatecall(abi.encodeWithSignature("setVars(uint256)", _num));
    }
}

// 逻辑合约
contract C {
    uint public num;
    address public sender;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
    }
}