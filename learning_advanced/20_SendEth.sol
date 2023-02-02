// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SendEth {
    // 构造函数，payable使得部署的时候可以转eth进去
    constructor() payable {}
    // receive方法，接收eth时被触发
    receive() external payable {}

    error SendFailed(); // 用send发送ETH失败error
    error CallFailed(); // 用call发送ETH失败error

    /**
    * 发送ETH方法一
    * 用法是接收方地址.transfer(发送ETH数额)。
    * _to ReceiveETH合约的地址
    * amount ETH转账金额
    * transfer()如果转账失败，会自动revert（回滚交易），是转账的次优选择
    */
    function transferETH(address payable _to, uint256 amount) external payable{
        _to.transfer(amount);
    }

    /**
    * 发送ETH方法二
    * 用法是接收方地址.send(发送ETH数额)。
    * _to ReceiveETH合约的地址
    * amount ETH转账金额
    * send()如果转账失败，不会revert，几乎没人用。
    * send()的返回值是bool，代表着转账成功或失败，可以使用额外代码处理。（transfer没有返回值）
    */
    function sendEth(address payable _to, uint256 amount) external payable {
        bool success = _to.send(amount);
        if (!success) {
            revert SendFailed();
        }
    }

    /**
    * 发送ETH方法三
    * 用法是 接收方地址.call{value: 发送ETH数额}("")。
    * _to ReceiveETH合约的地址
    * amount ETH转账金额
    * call()没有gas限制，可以支持对方合约fallback()或receive()函数实现复杂逻辑,是最提倡的方法。
    * call()如果转账失败，不会revert。（不同于transfer）
    * call()的返回值是(bool, data)，bool代表着转账成功或失败，可以使用额外代码处理。（transfer没有返回值）
    */
    function callEth(address payable _to, uint256 amount) external payable {
        (bool success,) = _to.call{value: amount}("");
        if (!success) {
            revert CallFailed();
        }
    }
}