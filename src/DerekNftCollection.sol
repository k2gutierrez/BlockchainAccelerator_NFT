// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC721A } from "../lib/ERC721A/contracts/ERC721A.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Derek NFT Collection
 * @author Carlos Gutiérrez
 * @notice ERC721A Collection
 */
contract DerekNftCollection is ERC721A, Ownable, ReentrancyGuard {

    error DerekNftCollection__SoldOut();
    error DerekNftCollection__TokenDoesNotExists();
    error DerekNftCollection__IncorrectPrice();
    error DerekNftCollection__CannotMintThatQuantityPerWallet();
    error DerekNftCollection__SoulBoundNFT();
    error NFTMock__NoBalanceInContract();
    error NFTMock__TransferFailed();

    using Strings for uint256;

    bool private immutable i_soulbound;
    uint256 private immutable i_MaxSupply;
    uint256 private s_NftPrice;
    uint256 private s_MaxPerWallet;

    mapping(uint256 => bool) private s_IsEvolved;

    // URIs for making it a dynamic NFT
    string private s_UriStateBase; // ej "ipfs://.../base/"
    string private s_UriStateEvolved; // ej "ipfs://.../evolved/"

    event MintNFT(address userAddress, uint256 amountOfNfts);

    constructor(bool _soulbound, address _owner, string memory _UriBase, string memory _UriEvolved, string memory _name, string memory _symbol, uint256 _maxSupply, uint256 _maxPerWallet, uint256 _price) 
        ERC721A(_name, _symbol) 
        Ownable(_owner) 
    {
        i_soulbound = _soulbound;
        s_UriStateBase = _UriBase;
        s_UriStateEvolved = _UriEvolved;
        i_MaxSupply = _maxSupply;
        s_MaxPerWallet = _maxPerWallet;
        s_NftPrice = _price;
    }

    // Owner functions
    /**
     * @dev Admin function to update the metadata links if needed
     * @param _UriBase The new url for Base URI.
     * @param _UriEvolved THE new url for Evolved URI
     */
    function setUris(string memory _UriBase, string memory _UriEvolved) external onlyOwner {
        s_UriStateBase = _UriBase;
        s_UriStateEvolved = _UriEvolved;
    }

    /**
     * @dev Set nft price
     * @param _newAmount New Price for token
     */
    function setNftPrice(uint256 _newAmount) external onlyOwner {
        s_NftPrice = _newAmount;
    }

    /**
     * @dev Set max per wallet allowed
     * @param _newAmountAllowed New amount allowed per wallet
     */
    function setMaxPerWallet(uint256 _newAmountAllowed) external onlyOwner {
        s_MaxPerWallet = _newAmountAllowed;
    }

    /**
     * @dev Withdrawe balance from contract
     */
    function withdrawBalance() external onlyOwner nonReentrant {
        if (address(this).balance == 0) revert NFTMock__NoBalanceInContract();
        uint256 balanceToWithdraw = address(this).balance;

        (bool success, ) = owner().call{value: balanceToWithdraw}("");
        if (!success) revert NFTMock__TransferFailed();
    }

    // Functions
    /**
     * @dev Mint function
     * @param _quantity Amount of tokens to mint
     */
    function mint(uint256 _quantity) external payable nonReentrant {
        uint256 balanceOfUser = balanceOf(msg.sender);
        uint256 maxPerWallet = s_MaxPerWallet;
        if (_quantity > maxPerWallet || (_quantity + balanceOfUser) > maxPerWallet) revert DerekNftCollection__CannotMintThatQuantityPerWallet();
        if (msg.value != (s_NftPrice * _quantity)) revert DerekNftCollection__IncorrectPrice();
        if ((totalSupply() + _quantity) > i_MaxSupply) revert DerekNftCollection__SoldOut();
        _safeMint(msg.sender, _quantity);
        emit MintNFT(msg.sender, _quantity);
    }

    /**
     * @dev Nft Owner calls this to toggle their own NFT state between base and evolved
     * @param tokenId Token ID for changing its own state.
     */
    function toggleState(uint256 tokenId) external {
        if (!_exists(tokenId)) revert DerekNftCollection__TokenDoesNotExists();
        if (ownerOf(tokenId) != msg.sender) revert("Not your token");
        
        s_IsEvolved[tokenId] = !s_IsEvolved[tokenId];
    }

    /**
     * @dev Hook used to check if the NFTs are soulbound or not before any token transfer.
     * @param from address that is sending the token
     * @param to address that will receive the token
     * @param startTokenId The first token that will be transferred, in ERC721 you can mint multiple tokens in one transaction
     * @param quantity amount of tokens to be transferred
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (i_soulbound) {
            if (from != address(0) && to != address(0)) revert DerekNftCollection__SoulBoundNFT();
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @dev Used to start with token ID 1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns different URI based on the bool
     * @param tokenId NFT Token ID to get correct URI.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        bool evolved = s_IsEvolved[tokenId];
        
        string memory baseURI = evolved ? s_UriStateEvolved : s_UriStateBase;

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) 
            : "";
    }

    /**
     * @dev Get max supply
     * @return maxSupply
     */
    function getMaxSupply() external view returns(uint256 maxSupply) {
        maxSupply = i_MaxSupply;
    }

    /**
     * @dev Get max per wallet allowed
     * @return maxPerWallet
     */
    function getMaxPerWallet() external view returns(uint256 maxPerWallet) {
        maxPerWallet = s_MaxPerWallet;
    }

    /**
     * @dev Get nft price
     * @return price
     */
    function getNftPrice() external view returns(uint256 price) {
        price = s_NftPrice;
    }

    /**
     * @dev Check if it is soulbound
     * @return  soulbound
     */
    function getIsSoulbound() external view returns(bool soulbound) {
        soulbound = i_soulbound;
    }

    /**
     * @dev Get URIs
     * @return UriBase 
     * @return UriEvolved 
     */
    function getURIs() external view returns(string memory UriBase, string memory UriEvolved) {
        UriBase = s_UriStateBase;
        UriEvolved = s_UriStateEvolved;
    }

    /**
     * @dev Get Nft status
     * @param tokenId Token Id
     */
    function getNftStatus(uint256 tokenId) external view returns(bool status) {
        status = s_IsEvolved[tokenId];
    }
    
}
