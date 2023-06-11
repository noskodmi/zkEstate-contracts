// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EstateToken is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Rental {
        address user;
        uint256 expires;
    }

    mapping(uint256 => Rental) public rentals;
    mapping(address => bool) public whitelistedUsers;

    constructor() ERC721("ZKEstateToken", "ESTATE") {}

    function mint(address to, string memory tokenURI) public {
        require(whitelistedUsers[msg.sender], "User not whitelisted for minting");
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function rent(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(rentals[tokenId].expires < block.timestamp, "Token is already rented");

        uint256 duration = 31536000;
        rentals[tokenId] = Rental(msg.sender, block.timestamp + duration);
    }

    function isUser(uint256 tokenId, address account) public view returns (bool) {
        return rentals[tokenId].user == account && rentals[tokenId].expires >= block.timestamp;
    }

    function reclaim(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");

        rentals[tokenId] = Rental(address(0), 0);
    }

    function addToWhitelist(address user) public onlyOwner {
        whitelistedUsers[user] = true;
    }

    function removeFromWhitelist(address user) public onlyOwner {
        whitelistedUsers[user] = false;
    }
}