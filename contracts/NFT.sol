// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFT is ERC721Enumerable {
    
    uint public constant MAX_TOKENS = 10000;

    constructor() ERC721("NFT", "NFT") { 

    }

    function mint(uint _numTokens) public {
        for (uint i = 0; i < _numTokens; i++) {
            uint tokenId = totalSupply() + 1;
            require(tokenId <= MAX_TOKENS, "No more tokens available.");
            _safeMint(msg.sender, tokenId);
        }
    }

    function tokensOfOwner(address _owner) external view returns(uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            for (uint index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}
