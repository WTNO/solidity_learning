// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 简单的可升级合约，管理员可以通过升级函数更改逻辑合约地址，从而改变合约的逻辑。
contract SimpleUpgrade {
    // 逻辑合约地址
    address public implementation;
    // admin地址
    address public admin; 
    // 字符串，可以通过逻辑合约的函数改变
    string public words;

    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback函数，将调用委托给逻辑合约
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // 升级函数，改变逻辑合约地址，只能由admin调用
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}