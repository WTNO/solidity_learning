// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ReceiveEth {
    // 定义事件
    event Received(address Sender, uint data);
    event fallbackCalled(address Sender, uint Value, bytes data);

    // 收到eth事件，记录amount和gas
    event Log(uint amount, uint gas);

    // receive()只用于处理接收ETH。一个合约最多有一个receive()函数
    // 声明方式与一般函数不一样，<不需要function关键字>
    // 当合约接收ETH的时候，receive()会被触发。
    // 不能有任何的参数，不能返回任何值，必须包含external和payable
    receive() external payable {
        // 接收ETH时释放Received事件
        // emit Received(msg.sender, msg.value);
        emit Log(msg.value, gasleft());
    }

    // 返回合约ETH余额
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // fallback()函数会在调用合约不存在的函数时被触发。
    // 可用于接收ETH，也可以用于代理合约proxy contract。
    // fallback()声明时不需要function关键字，必须由external修饰，一般也会用payable修饰，用于接收ETH
    fallback() external payable{
        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }

    // 触发fallback() 还是 receive()?
    //            接收ETH
    //               |
    //          msg.data是空？
    //             /  \
    //           是    否
    //           /      \
    // receive()存在?   fallback()
    //         / \
    //        是  否
    //       /     \
    // receive()   fallback()

    // receive()和payable fallback()均不存在的时候，向合约直接发送ETH将会报错

    
}