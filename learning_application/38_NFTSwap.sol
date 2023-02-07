// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./34_IERC721.sol";
import "./34_IERC721Receiver.sol";

    /**
     * 理解：
     * 在NFTSwap合约当中，出现了四个角色（地址），分别是NFT交易所（NFTSwap合约）、买家、卖家、NFT合约
     * 从全局来看，address(this)是NFTSwap合约，nftAddr是交易的NFT合约地址，order.owner是NFT持有人（卖家地址）
     * 在list、revoke、update三个函数中，msg.sender是卖家地址
     * 在purchase函数中，msg.sender是买家
     * list挂单：卖家(msg.sender)将NFT safeTransfer到NFTSwap(address(this)) PS:(从这里看出nftAddr + tokenId是唯一的)
     * revoke撤单:由持有人发起,NFTSwap(address(this))将NFT safeTransfer到卖家(msg.sender)
     * update修改价格:由持有人发起,获取order修改price
     * purchase购买:如果msg.value足够，由NFTSwap(address(this))将NFT safeTransfer到买家，调用payable.transfer将ETH转移给卖家,余额退回给买家
     */
contract NFTSwap is IERC721Receiver {
    // 挂单
    event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    // 购买
    event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
    // 撤单
    event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);    
    // 修改价格
    event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice);

    // NFT订单
    struct Order {
        address owner;
        uint256 price;
    }
    // NFT Order映射:订单是对应的NFT系列（合约地址）和tokenId信息。
    mapping(address => mapping(uint256 => Order)) public nftList;

    // 实现fallback()函数来接收ETH。
    fallback() external payable{}
    receive() external payable{}

    /**
     * 卖家创建NFT并创建订单，并释放List事件。成功后，NFT会从卖家转到NFTSwap合约中。
     * NFT合约地址nftAddr，NFT对应的tokenId，挂单价格price（注意：单位是wei）
     */
    function list(address nftAddr, uint256 tokenId, uint256 price) public {
        // 声明IERC721接口合约变量
        IERC721 nft = IERC721(nftAddr);
        // 合约得到授权
        require(nft.getApproved(tokenId) == address(this), "need Approval");
        // 价格大于0
        require(price > 0, "Invalid Price");
        //设置NF持有人和价格
        Order storage order = nftList[nftAddr][tokenId];
        order.owner = msg.sender;
        order.price = price;
        // 将NFT转账到合约
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        // 释放List事件
        emit List(msg.sender, nftAddr, tokenId, price);
    }

    /**
     * 撤单，卖家取消挂单，成功后，NFT会从NFTSwap合约转回卖家。
     * NFT合约地址nftAddr，NFT对应的tokenId。
     */
    function revoke(address nftAddr, uint256 tokenId) public {
        // 获取order
        Order storage order = nftList[nftAddr][tokenId];
        //必须由持有人发起
        require(order.owner == msg.sender, "Not Owner");
        // 声明IERC721接口合约变量
        IERC721 nft = IERC721(nftAddr);
        // NFT在合约中
        require(nft.ownerOf(tokenId) == address(this), "Invalid Order");
        // 将NFT转给卖家
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        // 删除order
        delete nftList[nftAddr][tokenId];
        // 释放Revoke事件
        emit Revoke(msg.sender, nftAddr, tokenId);
    }

    /**
     * 卖家修改NFT订单价格
     * 参数为NFT合约地址nftAddr，NFT对应的tokenId，更新后的挂单价格newPrice（注意：单位是wei）。
     */
    function update(address nftAddr, uint256 tokenId, uint256 newPrice) public {
        // NFT价格大于0
        require(newPrice > 0, "Invalid Price");
        // 取得Order
        Order storage order = nftList[nftAddr][tokenId];
        // 必须由持有人发起
        require(order.owner == msg.sender, "Not Owner");
        // 声明IERC721接口合约变量
        IERC721 nft = IERC721(nftAddr);
        // NFT在合约中
        require(nft.ownerOf(tokenId) == address(this), "Invalid Order");
        // 调整NFT价格
        order.price = newPrice;
        // 释放Update事件
        emit Update(msg.sender, nftAddr, tokenId, newPrice);
    }

    /**
     * 买家支付ETH购买挂单的NFT，并释放Purchase事件。
     * 参数为NFT合约地址nftAddr，NFT对应的tokenId。成功后，ETH将转给卖家，NFT将从NFTSwap合约转给买家。
     * 买家购买NFT，合约为nftAddr，tokenId为tokenId，调用函数时要附带ETH
     */
    function purchase(address nftAddr, uint256 tokenId) payable public {
        // 取得Order
        Order storage order = nftList[nftAddr][tokenId];
        // NFT价格大于0
        require(order.price > 0, "Invalid Price");
        // 购买价格大于标价
        require(msg.value >= order.price, "Increase price");
        // 声明IERC721接口合约变量
        IERC721 nft = IERC721(nftAddr);
        // NFT在合约中
        require(nft.ownerOf(tokenId) == address(this), "Invalid Order");
        // 将NFT转给买家
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        // 将ETH转给卖家，多余ETH给买家退款
        payable(order.owner).transfer(order.price);
        payable(msg.sender).transfer(msg.value - order.price);
        // 删除order
        delete nftList[nftAddr][tokenId];
        // 释放Purchase事件
        emit Purchase(msg.sender, nftAddr, tokenId, msg.value);
    }

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external pure override returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }
}