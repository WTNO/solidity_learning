// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./31_IERC20.sol";

/**
 * 本节测试失败！！！
 * 空投是币圈中一种营销策略，项目方将代币免费发放给特定用户群体。
 * 每次接收空投的用户很多，项目方不可能一笔一笔的转账。利用智能合约批量发放ERC20代币，可以显著提高空投效率。
 */
contract Airdrop {
    /**
     * 向多个地址转账ERC20代币，使用前需要先授权
     *
     * @param _token 转账的ERC20代币地址
     * @param _addresses 空投地址数组
     * @param _amounts 代币数量数组（每个地址的空投数量）
     */
    function sendAirdrop(address _token, address[] calldata _addresses, uint256[] calldata _amounts) external {
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        IERC20 ierc20 = IERC20(_token);
        // 统计空投所需代币总和
        uint256 amount = getSum(_amounts);
        // 授权代币数量 >= 空投代币总量
        require(ierc20.allowance(msg.sender, address(this)) >= amount, "Need Approve ERC20 token");

        for (uint i; i < _addresses.length; i++) {
            ierc20.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    /**
     * 向多个地址转账ERC20代币，使用前需要先授权
     *
     * @param _addresses 空投地址数组
     * @param _amounts ETH数量数组（每个地址的空投数量）
     */
    function multiTransferETH(address payable [] calldata _addresses, uint256[] calldata _amounts) external payable {
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        // 统计空投ETH总和
        uint256 amount = getSum(_amounts);
        // 转入ETH等于空投总量
        require(msg.value == amount, "Transfer amount error");
        for (uint i; i < _addresses.length; i++) {
            _addresses[i].transfer(_amounts[i]);
        }
    }

    function getSum(uint256[] calldata _arr) public pure returns(uint sum) {
        for(uint i = 0; i < _arr.length; i++)
            sum = sum + _arr[i];
    }
}