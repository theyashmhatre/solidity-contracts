//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsUpForSale;
    Counters.Counter private _itemsSold;
    Counters.Counter public collectionsCount;
    Counters.Counter public userCount;

    address payable owner;

    mapping(uint256 => SingleItem) public idToSingleItem;
    mapping(address => User) public idToUser;

    // uint[] private collectionIdList;
    mapping(uint256 => uint256[]) private collection;
    mapping(uint256 => CollectionData) public idToCollectionData;

    struct SingleItem {uint256 tokenId; address payable creator; address payable owner; address payable seller; uint royalty; string tokenURI; uint price; bool sold; bool isListed; uint collectionId;}

    struct User {uint userId; string name; string imageURL; bool userCreated;}

    struct CollectionData {uint256 collectionId; string name; string description; string imageURL; address createdBy;}

    event MarketItemCreated (uint256 indexed tokenId, address seller, address owner, uint256 price, bool sold );

    constructor() ERC721("NFT Dungeon", "NFTD") {
      owner = payable(msg.sender);
    }

    function createCollection(string memory name, string memory description, string memory imageURL) public {
        collectionsCount.increment();
        uint currentCount = collectionsCount.current();
        idToCollectionData[currentCount] = CollectionData(currentCount, name, description, imageURL, msg.sender);
        // collectionIdList.push(currentCount);
    }

    function addToCollection(uint tokenID, uint collectionID) public {
        if (_tokenIds.current() >= tokenID) {
          collection[collectionID].push(tokenID);
          idToSingleItem[tokenID].collectionId = collectionID;
        }
    }

    function getAllCollections() public view returns(CollectionData[] memory) {
      CollectionData[] memory collections = new CollectionData[](collectionsCount.current());

      for (uint i=0; i < collectionsCount.current(); i++) {
          uint currentId = i + 1;
          CollectionData storage currentItem = idToCollectionData[currentId];
          collections[i] = currentItem;
      } 

      return collections;
        
    }

    function getSingleCollection(uint collectionID) public view returns (SingleItem[] memory, CollectionData memory) {

        SingleItem[] memory items = new SingleItem[](collection[collectionID].length);

        for (uint i = 0; i < collection[collectionID].length; i++) {
          SingleItem storage currentItem = idToSingleItem[collection[collectionID][i]];
          items[i] = currentItem;
        }

        return (items, idToCollectionData[collectionID]); 
    }

    function createUser(string memory name, string memory imageURL) public {
      if (!idToUser[msg.sender].userCreated) {
          userCount.increment();
      }
     
      idToUser[msg.sender] = User(userCount.current(), name, imageURL, true);
    }

    /* Mints a token */
    function createToken(string memory tokenURI, uint256 price, uint collectionId, uint royalty) public returns (uint) {
      _tokenIds.increment();
      uint newTokenId = _tokenIds.current();

      _mint(msg.sender, newTokenId);
      _setTokenURI(newTokenId, tokenURI);
      idToSingleItem[newTokenId] = SingleItem(newTokenId, payable(msg.sender), payable(msg.sender), payable(msg.sender), royalty, tokenURI, price, false, false, collectionId);
      return newTokenId;
    }

    /* lists the token on the marketplace */
    function createMarketItem(
      uint tokenId,
      uint price,
      uint collectionId
    ) public {
      require(price > 0, "Price must be at least 1 wei");
      require(idToSingleItem[tokenId].owner == msg.sender, "not owner");

      _itemsUpForSale.increment();

      idToSingleItem[tokenId].isListed = true;
      idToSingleItem[tokenId].price = price;
      idToSingleItem[tokenId].owner = payable(address(this));
      idToSingleItem[tokenId].seller = payable(msg.sender);
      idToSingleItem[tokenId].collectionId = collectionId;
      idToSingleItem[tokenId].sold = false;

      _transfer(msg.sender, address(this), tokenId);

      emit MarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(
      uint256 tokenId
      ) public payable {
      uint price = idToSingleItem[tokenId].price;
      require(msg.value == price, "enter valid price");

      uint royaltyValue = (msg.value * idToSingleItem[tokenId].royalty) / 100;
      uint finalPrice = msg.value - royaltyValue;
      
      idToSingleItem[tokenId].owner = payable(msg.sender);

      idToSingleItem[tokenId].sold = true;
      idToSingleItem[tokenId].isListed = false;
      
      _itemsSold.increment();
      _transfer(address(this), msg.sender, tokenId);
      payable(idToSingleItem[tokenId].seller).transfer(finalPrice);
      payable(idToSingleItem[tokenId].creator).transfer(royaltyValue);
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (SingleItem[] memory) {
      uint itemCount = _itemsUpForSale.current();
      uint unsoldItemCount = _itemsUpForSale.current() - _itemsSold.current();
      uint currentIndex = 0;

      SingleItem[] memory items = new SingleItem[](unsoldItemCount);
      for (uint i = 0; i < itemCount; i++) {
        if (idToSingleItem[i + 1].owner == address(this)) {
          uint currentId = i + 1;
          SingleItem storage currentItem = idToSingleItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (SingleItem[] memory) {
      uint totalItemCount = _itemsUpForSale.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToSingleItem[i + 1].owner == msg.sender) {
          itemCount += 1;
        }
      }

      SingleItem[] memory items = new SingleItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToSingleItem[i + 1].owner == msg.sender) {
          uint currentId = i + 1;
          SingleItem storage currentItem = idToSingleItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (SingleItem[] memory) {
      uint totalItemCount = _itemsUpForSale.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToSingleItem[i + 1].seller == msg.sender) {
          itemCount += 1;
        }
      }

      SingleItem[] memory items = new SingleItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToSingleItem[i + 1].seller == msg.sender) {
          uint currentId = i + 1;
          SingleItem storage currentItem = idToSingleItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    function fetchAllNFTs() public view returns (SingleItem[] memory) {
      uint totalCount = _tokenIds.current();

      SingleItem[] memory items = new SingleItem[](totalCount);

      for (uint i = 0; i< totalCount; i++) {
        SingleItem storage currentItem = idToSingleItem[i+1];
        items[i] = currentItem;
      }

      return items;
    }
}