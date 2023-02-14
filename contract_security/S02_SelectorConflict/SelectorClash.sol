// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SelectorClash {
    bool public solved;

    event LOG(bytes methodId);

    // 攻击者需要调用这个函数，但是调用者 msg.sender 必须是本合约。
    function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
        require(msg.sender == address(this), "Not Owner");
        solved = true;
    }

    // 有漏洞，攻击者可以通过改变 _method 变量碰撞函数选择器，调用目标函数并完成攻击。
    function executeCrossChainTx(
        bytes memory _method,
        bytes memory _bytes,
        bytes memory _bytes1,
        uint64 _num
    ) public returns (bool success) {
        bytes memory signature1 = abi.encodeWithSignature(
            "putCurEpochConPubKeyBytes()",
            _method
        );
        emit LOG(signature1);
        bytes memory signature2 = abi.encodePacked(
            bytes4(keccak256(abi.encodePacked(_method, "(bytes,bytes,uint64)"))),
            abi.encode(_bytes, _bytes1, _num)
        );
        emit LOG(signature2);
        (success, ) = address(this).call(signature2);
    }
}
