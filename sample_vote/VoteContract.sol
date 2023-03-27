// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 投票合约
contract VoteContract {
    bytes voteTopic;
    bytes discription;
    uint256 timeLimit;
    bytes32[] options;
    mapping(bytes32 => uint256) voteResult;

    constructor(bytes memory _voteTopic, bytes memory _discription, uint256 _timeLimit,  bytes32[] memory _options) {
        voteTopic = _voteTopic;
        discription = _discription;
        timeLimit = _timeLimit;
        options = _options;
    }

}