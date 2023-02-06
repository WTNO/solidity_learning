// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./34_ERC721.sol";

contract WTFApe is ERC721 {
    uint public MAX_APES = 10000;

    constructor(string memory _name, string memory _symbol) ERC721(name, symbol) {
    } 

    //BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/ 
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    // 铸造函数
    function mint(address to, uint tokenId) external {
        require(tokenId >= 0 && tokenId < MAX_APES, "tokenId out of range");
        _mint(to, tokenId);
    }
}