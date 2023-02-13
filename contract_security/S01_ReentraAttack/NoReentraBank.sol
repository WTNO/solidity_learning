// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Bank {
    uint256 private _status; // 重入锁
    
    // 重入锁
    modifier nonReentrant() {
        // 在第一次调用 nonReentrant 时，_status 将是 0
        require(_status == 0, "ReentrancyGuard: reentrant call");
        // 在此之后对 nonReentrant 的任何调用都将失败
        _status = 1;
        _;
        // 调用结束，将 _status 恢复为0
        _status = 0;
    }

    mapping (address => uint256) public balanceOf;    // 余额mapping

    // 存入ether，并更新余额
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // 用重入锁保护有漏洞的函数
    function withdraw() external nonReentrant {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");

        balanceOf[msg.sender] = 0;
    }

    // 获取银行合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}