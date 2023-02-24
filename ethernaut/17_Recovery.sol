// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 合约创建者构建了一个非常简单的代币工厂合约。 任何人都可以轻松创建新代币。 
 * 在部署了一个代币合约后，创建者发送了 0.001 以太币以获得更多代币。 后边他们丢失了合约地址。
 * 如果您能从丢失的的合约地址中找回(或移除)，则顺利通过此关。
 *
 * 初步思路：使用地址预测，new的时候没有指定salt，所以使用的是create不是create2
 */
contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    // constructor
    constructor(
        string memory _name,
        address _creator,
        uint256 _initialSupply
    ) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // clean up after ourselves
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}

contract Attack {
    function calculateAddr(address createAddr, uint256 nonce) public view returns(address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(createAddr, nonce)))));
    }
}
