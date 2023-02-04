// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./31_IERC20.sol";

/**
 * 让用户免费领代币的网站/应用。
 * 逻辑：将一些ERC20代币转到水龙头合约里，用户可以通过合约的requestToken()函数来领取100单位的代币，每个地址只能领一次。
 */
contract CoinFaucet {
    // 存储领取记录
    mapping(address => bool) public record;
    // 记录合约发放的ERC20代币合约地址
    address public tokenContract;
    // 每次能领取的代币数量
    uint256 public amountAllowed = 100;

    event SendToken(address indexed receiver, uint256 indexed amount);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    // 用户领取代币
    function requestToken() external {
        require(record[msg.sender] == false, "Can't Request Multiple Times!");
        IERC20 ierc20 = IERC20(tokenContract);
        require(ierc20.balanceOf(address(this)) > amountAllowed, "Faucet Empty!");
        ierc20.transfer(msg.sender, amountAllowed);
        record[msg.sender] = true;
        emit SendToken(msg.sender, amountAllowed);
    }
}