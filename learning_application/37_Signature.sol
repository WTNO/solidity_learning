// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Signature {
    /*
     * 将mint地址（address类型）和tokenId（uint256类型）拼成消息msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 对应的消息msgHash: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address account, uint256 tokenId) external pure returns(bytes32){
        return keccak256(abi.encodePacked(account, tokenId));
    }

    /**
     * @dev 通过ECDSA，验证签名地址是否正确，如果正确则返回true
     * _msgHash为消息的hash
     * _signature为签名
     * _signer为签名地址
     */
    function verify(bytes32 msgHash, bytes memory signature, address signer) internal pure returns(bool) {
        return recoverSigner(msgHash, signature) == signer;
    }

    // @dev 从_msgHash和签名_signature中恢复signer地址
    function recoverSigner(bytes32 msgHash, bytes memory signature) internal pure returns(address) {
        // 检查签名长度，65是标准r,s,v签名的长度
        require(signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // 目前只能用assembly (内联汇编)来从签名中获得r,s,v的值
        assembly {
            /*
            前32 bytes存储签名的长度 (动态数组存储规则)
            add(sig, 32) = sig的指针 + 32
            等效为略过signature的前32 bytes
            mload(p) 载入从内存地址p起始的接下来32 bytes数据
            */
            // 读取长度数据后的32 bytes
            r := mload(add(signature, 0x20))
            // 读取之后的32 bytes
            s := mload(add(signature, 0x40))
            // 读取最后一个byte
            v := byte(0, mload(add(signature, 0x60)))
        }
        // 使用ecrecover(全局函数)：利用 msgHash 和 r,s,v 恢复 signer 地址
        return ecrecover(msgHash, v, r, s);
    }

    /**
     * @dev 返回 以太坊签名消息
     * `hash`：消息
     * 遵从以太坊签名标准：https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * 以及`EIP191`:https://eips.ethereum.org/EIPS/eip-191`
     * EIP191提倡在消息前加上"\x19Ethereum Signed Message:\n32"字符，并再做一次keccak256哈希，作为以太坊签名消息。
     * 经过toEthSignedMessageHash()函数处理后的消息，不能被用于执行交易:
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }


}