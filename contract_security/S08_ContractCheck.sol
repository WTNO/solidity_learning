// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ContractCheck is ERC20 {
    constructor() ERC20("", "") {}

    // 利用 extcodesize 检查是否为合约
    function isContract(address account) public view returns (bool) {
        // extcodesize > 0 的地址一定是合约地址
        // 但是合约在构造函数时候 extcodesize 为0
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // 如果调用者为 EOA，那么tx.origin和msg.sender相等；如果它们俩不想等，调用者为合约。
    function realContract(address account) public view returns (bool) {
        return (tx.origin == msg.sender);
    }

    function mint() public {
        require(realContract(msg.sender), "Contract not allowed!");
        _mint(msg.sender, 100);
    }
}

// 合约在被创建的时候，runtime bytecode 还没有被存储到地址上，因此 bytecode 长度为0。
// 也就是说，如果我们将逻辑写在合约的构造函数 constructor 中的话，就可以绕过 isContract() 检查。
contract NotContract {
    bool public isContract;
    address public contractCheck;

    // 当合约正在被创建时，extcodesize (代码长度) 为 0，因此不会被 isContract() 检测出。
    constructor(address addr) {
        contractCheck = addr;
        isContract = ContractCheck(addr).isContract(address(this));
        // This will work
        for(uint i; i < 10; i++){
            ContractCheck(addr).mint();
        }
    }

    // 合约创建好以后，extcodesize > 0，isContract() 可以检测
    function mint() external {
        ContractCheck(contractCheck).mint();
    }
}

