// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;
contract Fund {
    mapping(address => uint) shares;
    function withdraw() public {
        // if (payable(msg.sender).call.value(shares[msg.sender])())
        //     shares[msg.sender] = 0;
    }
}