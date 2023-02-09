// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./31_IERC20.sol";

/**
 * 锁仓并线性释放ERC20代币逻辑：
 * 项目方规定线性释放的起始时间、归属期和受益人。
 * 项目方将锁仓的ERC20代币转账给TokenVesting合约。
 * 受益人可以调用release函数，从合约中取出释放的代币。
 * (每个受益人单独对应一个线性释放合约？)
 */
contract TokenVesting {
    // 提币事件
    event ERC20Released(address indexed token, uint256 amount);

    // 代币地址->释放数量的映射，记录已经释放的代币
    mapping(address => uint256) public erc20Released;
    // 受益人地址
    address public immutable beneficiary; 
    // 起始时间戳
    uint256 public immutable start;
    // 归属期
    uint256 public immutable duration; 

    constructor(address _beneficiary, uint256 _duration) {
        require(_beneficiary != address(0), "VestingWallet: beneficiary is zero address");
        beneficiary = _beneficiary;
        start = block.timestamp;
        duration = _duration;
    }

    /**
     * @dev 受益人提取已释放的代币。
     * 调用vestedAmount()函数计算可提取的代币数量，然后transfer给受益人。
     * 释放 {ERC20Released} 事件.
     */
    function release(address tokenAddress) external {
        // 调用vestedAmount()函数计算可提取的代币数量
        uint256 releasable = vestedAmount(tokenAddress, uint256(block.timestamp)) - erc20Released[tokenAddress];
        // 更新已释放代币数量
        erc20Released[tokenAddress] += releasable;
        // 转代币给受益人
        emit ERC20Released(tokenAddress, releasable);
        IERC20(tokenAddress).transfer(beneficiary, releasable);
    }

    /**
     * @dev 根据线性释放公式，计算已经释放的数量。开发者可以通过修改这个函数，自定义释放方式。
     * @param token: 代币地址
     * @param timestamp: 查询的时间戳
     */
    function vestedAmount(address token, uint256 timestamp) internal view returns(uint256) {
        // 合约里总共收到了多少代币（当前余额 + 已经提取）(这里的意思是支持多个代币合约？)
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        // 根据线性释放公式，计算已经释放的数量
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}