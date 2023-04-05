// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AleoNft is ERC721, ERC721Enumerable, AccessControl,Ownable {
    using Strings for uint256;
    string public baseTokenURI;
    bytes32 public constant MINT_TOKEN_ROLE = keccak256("MINT_TOKEN_ROLE");    // Role that can mint tiger item
    bytes32 public constant SET_TOKEN_ROLE = keccak256("SET_TOKEN_ROLE");    // Role that can mint tiger item
    bytes32 public constant BURN_TOKEN_ROLE = keccak256("BURN_TOKEN_ROLE");    // Role that can mint tiger item

    mapping(uint256 => bool) public isLocked;
    mapping(address => uint256) public lockedAmount;
    

    constructor()
    ERC721("W3BULL", "W3BULL")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SET_TOKEN_ROLE, msg.sender);
        _setupRole(MINT_TOKEN_ROLE, msg.sender);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        string memory baseURI = _baseURI();
        string memory uriSuffix = Strings.toString(tokenId);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, uriSuffix)) : '';
    }

   
    

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

 

    function setBaseURI(string memory _baseTokenURI) public onlyRole(SET_TOKEN_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

   

    function mintToken(uint256 _tokenId, address to ) public onlyRole(MINT_TOKEN_ROLE) {
        require(!_exists(_tokenId), 'The token URI should be unique');
        _safeMint(to, _tokenId);
        isLocked[_tokenId] = true;
        lockedAmount[to]++;
         
    }

    function burnToken(uint256 _tokenId) public onlyRole(BURN_TOKEN_ROLE) {
        _burn(_tokenId);
    }

    function burn(uint256 _tokenId) public  {
        require(ownerOf(_tokenId) == msg.sender, 'not your token');
        _burn(_tokenId);
    }




    function lockToken(uint256[] memory _tokenIds) public{
         for (uint256 i = 0; i < _tokenIds.length; i++) { 
            uint256 _tokenId = _tokenIds[i];
            require(ownerOf(_tokenId) == msg.sender, 'not your token');
            if(!isLocked[_tokenId]){
                isLocked[_tokenId] = true;
                lockedAmount[ownerOf(_tokenId)]++;
            }
            
        }

    }

    function unLockToken(uint256[] memory _tokenIds) public{
         for (uint256 i = 0; i < _tokenIds.length; i++) { 
            uint256 _tokenId = _tokenIds[i];
            require(ownerOf(_tokenId) == msg.sender, 'not your token');
            if(isLocked[_tokenId]){
                isLocked[_tokenId] = false;
                if(lockedAmount[ownerOf(_tokenId)] > 0){
                    lockedAmount[ownerOf(_tokenId)]--;
                }
            }
            
        }

    }


     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        require(!isLocked[tokenId] , "ERC721:  token is locked");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }


     function isApprovedOrOwner(address spender, uint256 tokenId) public view virtual   returns (bool) {
         return  _isApprovedOrOwner(spender,tokenId);
    }

    

}