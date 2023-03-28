// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 投票合约
contract VoteContract {
    bytes public voteTopic; // 投票主题
    bytes public discription; // 投票描述
    uint256 public timeLimit; // 时间限制
    bytes32[] public options; // 投票选项
    mapping(bytes32 => uint256) public voteResult; // 投票结果
    mapping(address => bool) public voteRecord; // 投票记录

    constructor(bytes memory _voteTopic, bytes memory _discription, uint256 _timeLimit,  bytes32[] memory _options) {
        voteTopic = _voteTopic;
        discription = _discription;
        timeLimit = _timeLimit;
        options = _options;
    }

    modifier timeLimited() {
        require(timeLimit > block.timestamp, "time out");
        _;
    }

    //投票，选票+1
    function vote(bytes32 option) public timeLimited {
        // 每个用户只能投票一次,且限制为账户地址，不能是合约，以防创建大量合约操纵结果
        require(!voteRecord[tx.origin], "Each user is eligible for one vote only");
        voteRecord[tx.origin] = true;
        voteResult[option] +=1;
    }

}