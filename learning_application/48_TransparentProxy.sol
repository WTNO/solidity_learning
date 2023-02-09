// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 透明代理合约
// 限制管理员的权限，不让他调用任何逻辑合约的函数，解决函数选择器冲突（说实话就加了一个admin验证，没看懂怎么解决了）
contract TransparentProxy {
    // logic合约地址
    address implementation;
    // 管理员
    address admin;
    // 字符串，可以通过逻辑合约的函数改变
    string public words;

    // 构造函数，初始化admin和逻辑合约地址
    constructor(address _implementation){
        admin = msg.sender;
        implementation = _implementation;
    }

    // fallback函数，将调用委托给逻辑合约
    fallback() external payable {
        // 不能被admin调用，避免选择器冲突引发意外
        require(msg.sender != admin);
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }

    // 升级函数，改变逻辑合约地址，只能由admin调用
    function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert();
        implementation = newImplementation;
    }
}