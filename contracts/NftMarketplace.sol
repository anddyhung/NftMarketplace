// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
// import '@openzeppelin/contracts/security/RentrancyGuard.sol';

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale (address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();

contract NftMarketplace{

       struct Listing {
        uint256 price;
        address seller;
    } 
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
     );
     event ItemCancelled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
     );
     event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
     );
     mapping(address=>mapping(uint256=>Listing)) private s_listings;
     mapping(address=>uint256) private s_proceeds;

     modifier notListed(address nftAddress, uint256 tokenId, address owner){
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(listing.price>0){
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
     }

     modifier isOwner(address nftAddress, uint256 tokenId, address spender){
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if(spender!=owner){
            revert NotOwner();
        }
        _;
     }

     modifier isListed(address nftAddress, uint256 tokenId){
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(listing.price<=0){
            revert NotListed(nftAddress, tokenId);
        }
        _;
     }
    //  modifier nonReentrant(){
    //      require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // // Any calls to nonReentrant after this point will fail
    // _status = _ENTERED;

    // _; // <--- everything before this is executed

    // // By storing the original value once again, a refund is triggered (see
    // // https://eips.ethereum.org/EIPS/eip-2200)
    // _status = _NOT_ENTERED;
    //  }
    function listItem(
        address nftAddress, uint256 tokenId, uint256 price
    )
     external 
     notListed(nftAddress, tokenId, msg.sender)
     isOwner(nftAddress, tokenId, msg.sender)
     {
        if(price<=0){
            revert PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if(nft.getApproved(tokenId)!=address(this)){
            revert NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
     }

     function cancelListing(address nftAddress, uint256 tokenId) 
     external 
     isOwner(nftAddress, tokenId, msg.sender) 
     isListed(nftAddress, tokenId)
     {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCancelled(msg.sender, nftAddress, tokenId);
     }
     function buyItem(address nftAddress, uint256 tokenId)
     external
     payable
     isListed(nftAddress, tokenId)
    //  nonReentrant
     {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if(msg.value<listedItem.price){
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }
        s_proceeds[listedItem.seller]+=msg.value;
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
     }
     function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice)
     external
     isListed(nftAddress, tokenId)
    //  nonReentra/// @notice Explain to an end user what this does
     /// @dev Explain to a developer any extra details
     /// @return Documents the return variables of a contract’s function state variable
     /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
     isOwner(nftAddress, tokenId, msg.sender)
     {
        if(newPrice ==0){
            revert PriceMustBeAboveZero();
        }
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
     }

    function withdrawProceeds() external{
        uint256 proceeds = s_proceeds[msg.sender];
        if(proceeds<=0){
            revert NoProceeds();
        }
        s_proceeds[msg.sender] =0;
        (bool success,)=payable(msg.sender).call{value:proceeds}('');
        require (success, 'Transfer fai=iled');
    }

    function getListing(address nfrAddress, uint256 tokenId)
    external view
    returns (Listing memory)
    {
        return s_listings[nfrAddress][tokenId];
    }
    function getProceeds(address seller) external view returns(uint256){
        return s_proceeds[seller];
    }
    

     
}