// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/Estate.sol" as Estate;

contract RentalNFT is ERC721Enumerable, Ownable {
    struct PropertyListing {
        uint256 id;
        address landlord;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 tokenId;
        string tokenURI;
    }

    struct TenantProposal {
        uint256 propertyId;
        address tenant;
        string metadataURI;
        bool isWinner;
    }

    Estate.EstateToken public constant ESTATE_TOKEN = Estate.EstateToken(0x35aB012bb736e915407877F7489b0651406D825d);

    // Counter for property listing IDs
    uint256 private _propertyListingIdCounter;

    // Mapping from property listing ID to PropertyListing struct
    mapping(uint256 => PropertyListing) public propertyListings;

    // Mapping from property listing ID to tenant proposal ID
    mapping(uint256 => uint256[]) public tenantProposalsByProperty;

    // Mapping from tenant proposal ID to TenantProposal struct
    mapping(uint256 => TenantProposal) public tenantProposals;

    // Events
    event PropertyListingCreated(uint256 indexed propertyId, address indexed landlord, string tokenURI);
    event TenantProposalSubmitted(uint256 indexed propertyId, uint256 indexed proposalId, address indexed tenant, string metadataURI);
    event WinnerSelected(uint256 indexed propertyId, uint256 indexed proposalId, address indexed tenant);
    event TenantProposalReclaimed(uint256 indexed propertyId, uint256 indexed proposalId, address indexed tenant);

    constructor() ERC721("RentalNFT", "RNFT") {}

    function createPropertyListing(uint256 startTime, uint256 endTime, uint256 tokenId, string memory tokenURI) external returns (uint256) {
        require(ESTATE_TOKEN.isUser(tokenId, _msgSender()), "Caller is not an ESTATE holder");
        _propertyListingIdCounter++;
        uint256 propertyId = _propertyListingIdCounter;
        PropertyListing storage newListing = propertyListings[propertyId];
        newListing.id = propertyId;
        newListing.landlord = _msgSender();
        newListing.startTime = startTime;
        newListing.endTime = endTime;
        newListing.isActive = true;
        newListing.tokenId = tokenId;
        newListing.tokenURI = tokenURI;

        emit PropertyListingCreated(propertyId, _msgSender(), tokenURI);
        return propertyId;
    }

    function submitTenantProposal(uint256 propertyId, string memory metadataURI) external returns (uint256) {
        require(propertyListings[propertyId].isActive, "Property listing is not active");

        uint256 tokenId = totalSupply() + 1;
        _safeMint(_msgSender(), tokenId);

        TenantProposal storage newProposal = tenantProposals[tokenId];
        newProposal.propertyId = propertyId;
        newProposal.tenant = _msgSender();
        newProposal.metadataURI = metadataURI;
        newProposal.isWinner = false;

        tenantProposalsByProperty[propertyId].push(tokenId);

        emit TenantProposalSubmitted(propertyId, tokenId, _msgSender(), metadataURI);
        return tokenId;
    }

    function selectWinner(uint256 propertyId, uint256 tokenId, string memory tokenURI) external {
        require(propertyListings[propertyId].landlord == _msgSender(), "Caller is not the landlord");
        require(tenantProposals[tokenId].propertyId == propertyId, "Invalid tenant proposal for the property");

        tenantProposals[tokenId].isWinner = true;
        propertyListings[propertyId].isActive = false;
        propertyListings[propertyId].tokenURI = tokenURI;

        emit WinnerSelected(propertyId, tokenId, tenantProposals[tokenId].tenant);
    }

    function reclaimUnsuccessfulProposals(uint256 propertyId) external {
        require(!propertyListings[propertyId].isActive, "Property listing is still active");
        require(propertyListings[propertyId].landlord == _msgSender(), "Caller is not the landlord");

        uint256[] storage proposals = tenantProposalsByProperty[propertyId];
        for (uint256 i = 0; i < proposals.length; i++) {
            uint256 tokenId = proposals[i];
            if (!tenantProposals[tokenId].isWinner) {
                _transfer(tenantProposals[tokenId].tenant, _msgSender(), tokenId);
                emit TenantProposalReclaimed(propertyId, tokenId, tenantProposals[tokenId].tenant);
            }
        }
    }
}