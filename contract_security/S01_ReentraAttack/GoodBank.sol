// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Bank {
    mapping (address => uint256) public balanceOf;    // 余额mapping

    // 存入ether，并更新余额
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        // 检查-效果-交互模式（checks-effect-interaction）：先更新余额变化，再发送ETH
        // 重入攻击的时候，balanceOf[msg.sender]已经被更新为0了，不能通过上面的检查。
        balanceOf[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
    }

    // 获取银行合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}