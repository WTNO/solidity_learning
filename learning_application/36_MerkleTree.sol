// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./34_ERC721.sol";
import "./36_MerkleProof.sol";

// 利用MerkleTree合约来发放NFT白名单
contract MerkleTree is ERC721 {
    bytes32 immutable public root;
    // 记录已经mint的地址
    mapping(address => bool) public mintedAddress;

    constructor(string memory name, string memory symbol, bytes32 merkleroot) ERC721(name, symbol) {
        root = merkleroot;
    }

    // 利用Merkle树验证地址并完成mint
    function mint(address account, uint256 tokenId, bytes32[] calldata proof) external {
        // Merkle检验通过
        require(_verify(_leaf(account), proof), "Invalid merkle proof");
        // 地址没有mint过
        require(!mintedAddress[account], "Already minted!");
        // mint
        _mint(account, tokenId); 
        // 记录mint过的地址
        mintedAddress[account] = true;
    }

    // Merkle树验证，调用MerkleProof库的verify()函数
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    // 计算Merkle树叶子的哈希值
    function _leaf(address account) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }
}