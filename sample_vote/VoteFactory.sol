// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VoteContract.sol";

// 投票合约工厂
contract VoteFactory {
    // 存储所有投票合约地址和对应主题
    mapping (address => bytes) public voteContractTopic;
    // 存储所有投票合约地址和对应的时间限制
    mapping (address => uint256) public voteContractTimeLimit;
    // admin名单
    mapping(address => bool) public adminList;
    // 合约所有者
    address public owner;

    modifier onlyAdmin() {
        require(adminList[msg.sender], "Admin Only!");
        _;
    }

    constructor() {
        owner = msg.sender;
        adminList[msg.sender] = true;
    }

    function createVote(bytes memory voteTopic, bytes memory discription, uint256 timeLimit,  bytes32[] memory options) external onlyAdmin returns(address contractAddr) {
        // 投票有效时间不能小于一小时
        require(timeLimit > block.timestamp + 60 * 60, "Insufficient voting time!");

        // 利用create2创建合约
        bytes32 salt = keccak256(abi.encodePacked(voteTopic, block.timestamp));
        address addressPre = calculateAddr(voteTopic);
        require(voteContractTimeLimit[addressPre] == 0, "create vote failed!"); // 预测的合约地址不能已存在
        VoteContract voteContract = new VoteContract{salt: salt}(voteTopic, discription, timeLimit, options);

        // 更新投票合约地址记录
        contractAddr = address(voteContract);
        voteContractTopic[contractAddr] = voteTopic;
        voteContractTimeLimit[contractAddr] = timeLimit;
    }

    // 添加管理员
    function addAdmin(address user) external {
        require(msg.sender == owner, "Not the owner");
        adminList[user] = true;
    }

    // 提前计算vote合约地址
    function calculateAddr(bytes memory voteTopic) private view returns(address contractAddr) {
        bytes32 salt = keccak256(abi.encodePacked(voteTopic, block.timestamp));
        contractAddr = address(uint160(uint(
            keccak256(
                abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(type(VoteContract).creationCode))
            )
        )));
    }

    
}