// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract tool {
    function get(string memory x) public pure returns(bytes memory result) {
        result = bytes(x);
    }
    
    function getBytes32(string memory x) public pure returns(bytes32 result) {
        result = bytes32(bytes(x));
    }

    function getTime() public view returns(uint256 time) {
        time = block.timestamp;
    }
}