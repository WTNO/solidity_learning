// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./34_ERC721.sol";
import "./37_ECDSA.sol";

// 私钥和公钥的关系是？
// 私钥: 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b
// signer/公钥:0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2
// account:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// token:0
// 消息：0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
// 以太坊签名消息：0xb42ca4636f721c7a331923e764587e98ec577cea1a185f60dfcc14dbb9bd900b
// 签名消息signature（通过钱包或者web3.py签名，过程中会用到私钥，暂时没懂，由 消息+账号 创建）:0x390d704d7ab732ce034203599ee93dd5d3cb0d4d1d7c600ac11726659489773d559b12d220f99f41d17651b0c1c6a669d346a397f8541760d6b32a5725378b241c
contract Signature is ERC721{
    // 签名地址
    address immutable public signer;
    // 记录已经mint的地址
    mapping(address => bool) public mintedAddress;

    constructor(string memory _name, string memory _symbol, address _signer) ERC721(_name, _symbol) {
        signer = _signer;
    }

    function mint(address _account, uint256 _tokenId, bytes memory _signature) external {
        // 将_account和_tokenId打包《消息》
        bytes32 messageHash = getMessageHash(_account, _tokenId);
        // 计算以太坊《签名消息signature》
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        // ECDSA检验通过
        require(ECDSA.verify(ethSignedMessageHash, _signature, signer), "Invalid signature");
        // 地址没有mint过
        require(!mintedAddress[_account], "Already minted!");
        // 记录mint过的地址
        mintedAddress[_account] = true;
        // mint
        _mint(_account, _tokenId);
    }

    /*
     * 将mint地址（address类型）和tokenId（uint256类型）拼成消息msgHash
     * _account: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * _tokenId: 0
     * 对应的消息msgHash: 0x1bf2c0ce4546651a1a2feb457b39d891a6b83931cc2454434f39961345ac378c
     */
    function getMessageHash(address account, uint256 tokenId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(account, tokenId));
    }
}