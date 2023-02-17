// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 1.获得这个合约的所有权
 * 2.把他的余额减到0
 * 
 * 获取合约所有权的function有两个，contribute至少需要调用1000 / (0.001) + 1 次，明显不可能，因此通过receive改变
 * 1.调用contribute()并转过去1Wei，此时getContribution()为1
 * 2.通过Transact按钮转过去1Wei,触发receive(),获取了合约的所有权
 * 3.调用withdraw
 */
contract Fallback {

  mapping(address => uint) public contributions;
  address public owner;

  constructor() {
    owner = msg.sender;
    contributions[msg.sender] = 1000 * (1 ether);
  }

  modifier onlyOwner {
        require(
            msg.sender == owner,
            "caller is not the owner"
        );
        _;
    }

  function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;
    if(contributions[msg.sender] > contributions[owner]) {
      owner = msg.sender;
    }
  }

  function getContribution() public view returns (uint) {
    return contributions[msg.sender];
  }

  function withdraw() public onlyOwner {
    payable(owner).transfer(address(this).balance);
  }

  receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
  }
}