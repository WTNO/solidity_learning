// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./31_IERC20.sol";

/**
 * 代币锁合约
 * 开发者在部署合约时规定锁仓的时间，受益人地址，以及代币合约。
 * 开发者将代币转入TokenLocker合约。
 * 在锁仓期满，受益人可以取走合约里的代币。
 */
contract TokenLocker {
    // 锁仓开始事件，在合约部署时释放，记录受益人地址，代币地址，锁仓起始时间，和结束时间
    event TokenLockStart(address indexed beneficiary, address indexed token, uint256 startTime, uint256 lockTime);
    // 代币释放事件，在受益人取出代币时释放，记录记录受益人地址，代币地址，释放代币时间，和代币数量。
    event Release(address indexed beneficiary, address indexed token, uint256 releaseTime, uint256 amount);

    // 被锁仓的ERC20代币合约
    IERC20 public immutable token;
    // 受益人地址
    address public immutable beneficiary;
    // 锁仓时间(秒)
    uint256 public immutable lockTime;
    // 锁仓起始时间戳(秒)
    uint256 public immutable startTime;

    // 注意，这里的入参是合约，但是传参时可以直接传递合约地址，不用传地址然后自己创建合约变量
    constructor(IERC20 _token, address _beneficiary, uint256 _lockTime) {
        require(_lockTime > 0, "TokenLock: lock time should greater than 0");
        token = _token;
        beneficiary = _beneficiary;
        lockTime = _lockTime;
        startTime = block.timestamp;
        // 锁仓开始事件
        emit TokenLockStart(_beneficiary, address(_token), block.timestamp, _lockTime);
    }

    /**
     * @dev 在锁仓时间过后，将代币释放给受益人。
     */
    function release() public {
        require(block.timestamp >= startTime+lockTime, "TokenLock: current time is before release time");
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenLock: no tokens to release");
        token.transfer(beneficiary, amount);
        emit Release(msg.sender, address(token), block.timestamp, amount);
    }
}