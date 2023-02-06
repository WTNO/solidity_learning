// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "./34_ERC721.sol";
import "https://github.com/AmazingAng/WTFSolidity/blob/main/34_ERC721/ERC721.sol";

contract DutchAuction is Ownable, ERC721 {
    // NFT总数
    uint256 public constant COLLECTOIN_SIZE = 10000;
    // 起拍价(最高价)
    uint256 public constant AUCTION_START_PRICE = 1 ether;
    // 结束价(最低价/地板价)
    uint256 public constant AUCTION_END_PRICE = 0.1 ether;
    // 拍卖时间，为了测试方便设为10分钟
    uint256 public constant AUCTION_TIME = 10 minutes;
    // 每过多久时间，价格衰减一次
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes;
    // 每次价格衰减步长
    uint256 public constant AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_TIME / AUCTION_DROP_INTERVAL);
    // 拍卖开始时间戳
    uint256 public auctionStartTime;
    // metadata URI
    string private _baseTokenURI;
    // 记录所有存在的tokenId 
    uint256[] private _allTokens;

    constructor() ERC721("WTF Dutch Auctoin", "WTF Dutch Auctoin") {
        auctionStartTime = block.timestamp;
    }

    // auctionStartTime setter函数，onlyOwner
    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }

    /**
     * 获取拍卖实时价格
     * 当block.timestamp小于起始时间，价格为最高价AUCTION_START_PRICE；
     * 当block.timestamp大于结束时间，价格为最低价AUCTION_END_PRICE；
     * 当block.timestamp处于两者之间时，则计算出当前的衰减价格。
     */
    function getAuctionPrice() public view returns(uint256) {
        if (block.timestamp < auctionStartTime) {
            return AUCTION_START_PRICE;
        } else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - auctionStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    /**
     * 1.检查拍卖是否开始/铸造是否超出NFT总量
     * 2.合约通过getAuctionPrice()和铸造数量计算拍卖成本，并检查用户支付的ETH是否足够
     * 3.如果足够，则将NFT铸造给用户，并退回超额的ETH；反之，则回退交易。
     */
    function auctionMint(uint256 quantity) external payable {
        // 建立local变量，减少gas花费(?)
        uint256 _saleStartTime = uint256(auctionStartTime);
        // 检查是否设置起拍时间，拍卖是否开始
        require(_saleStartTime != 0 && block.timestamp >= _saleStartTime, "sale has not start yet");
        // 检查是否超过NFT上限
        require(
            totalSupply() + quantity <= COLLECTOIN_SIZE,
            "not enough remaining reserved for auction to support desired mint amount"
            );
        
        // 计算mint成本
        uint256 totalCost = getAuctionPrice() * quantity; 
        // 检查用户是否支付足够ETH
        require(msg.value >= totalCost, "Need to send more ETH."); 

        // Mint NFT
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
            _addTokenToAllTokensEnumeration(mintIndex);
        }

        // 多余ETH退款
        if (msg.value > totalCost) {
            //注意一下这里是否有重入的风险(啥意思？)
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    // 提款函数，onlyOwner
    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}(""); // call函数的调用方式详见第22讲
        require(success, "Transfer failed.");
    }

     /**
      * ERC721Enumerable中totalSupply函数的实现
      */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * Private函数，在_allTokens中添加一个新的token
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokens.push(tokenId);
    }

}