// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./34_IERC165.sol";
import "./34_IERC721.sol";
import "./34_IERC721Receiver.sol";
import "./34_IERC721Metadata.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

abstract contract ERC721 is IERC721, IERC721Metadata {
    using Address for address; // 使用Address库，用isContract来判断地址是否为合约
    using Strings for uint256; // 使用String库，
    
    // Token名称
    string public override name;
    // Token代号
    string public override symbol;
    // tokenId 到 owner address 的持有人映射
    mapping(uint => address) private _owners;
    // address 到 持仓数量 的持仓量映射
    mapping(address => uint) private _balances;
    // tokenID 到 授权地址 的授权映射
    mapping(uint => address) private _tokenApprovals;
    //  owner地址。到operator地址 的批量授权映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // // 实现IERC165接口supportsInterface
    function supportsInterface(bytes4 interfaceId) external pure override returns(bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId;

    }

    function balanceOf(address owner) external view override returns(uint) {
        require(owner != address(0), "owner = zero address");
        return _balances[owner];
    }

    // 利用_owners变量查询tokenId的owner
    function ownerOf(uint tokenId) public view override returns(address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }

    // 利用_operatorApprovals变量查询owner地址是否将所持NFT批量授权给了operator地址。
    function isApprovedForAll(address owner, address operator) external view override returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    // 将持有代币全部授权给operator地址。调用_setApprovalForAll函数。
    function setApprovalForAll(address operator,bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 利用_tokenApprovals变量查询tokenId的授权地址。
    function getApproved(uint tokenId) external view override returns(address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    // 将tokenId授权给 to 地址。条件：to不是owner，且msg.sender是owner或授权地址。调用_approve函数。
    function approve(address to, uint tokenId) external override {
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    // 授权函数。通过调整_tokenApprovals来，授权 to 地址操作 tokenId，同时释放Approval事件。
    function _approve(address owner, address to, uint tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            return
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                ) == IERC721Receiver.onERC721Received.selector;
        } else {
            return true;
        }
    }
}