// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/math/SafeMath.sol";

/**
 * 获得以下合约的所有权来完成这一关
 *
 * 下面代码中的Fal1out并不是构造器，中间第二个l其实是1，可以直接调用这个方法！！！
 */
contract Fallout {
    using SafeMath for uint256;
    mapping(address => uint256) allocations;
    address payable public owner;

    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    // 给msg.sender（用户）转账并累加在allocations
    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    // 将allocator在合约的余额转账给allocator
    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }

    // 将合约的余额转账给msg.sender
    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    // 返回allocator的余额
    function allocatorBalance(address allocator) public view returns (uint256) {
        return allocations[allocator];
    }
}
