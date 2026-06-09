// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DerekNftCollection} from "../src/DerekNftCollection.sol";
import {DeployNftCollectionScript} from "../script/DerekNftCollectionScript.s.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract DerekNftCollectionTest is Test {

    using Strings for uint256;

    // Contract collection address
    DerekNftCollection public nftCollection;

    // Constants to check on contract = values from scripts
    bool constant SOULBOUND = true;
    string constant URI_BASE = "ipfs://fewfgwGRBase/";
    string constant URI_EVOLVED = "ipfs://fewfgwGREvolved/";
    string constant NAME = "Some NFT";
    string constant SYMBOL = "SNFT";
    uint256 constant MAX_SUPPLY = 10;
    uint256 constant MAX_PER_WALLET = 6;
    uint256 constant AMOUNT_DEAL_USER = 100 ether;
    uint256 constant PRICE = .5 ether;

    // Users addresses
    address owner;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        DeployNftCollectionScript deployer;
        deployer = new DeployNftCollectionScript();
        nftCollection = deployer.run();
        owner = nftCollection.owner();
        vm.deal(owner, AMOUNT_DEAL_USER);
        vm.deal(user1, AMOUNT_DEAL_USER);
        vm.deal(user2, AMOUNT_DEAL_USER);
    }

    // Owner functions
    function testSetUris() external {
        string memory newUriBase = "New Uri base";
        string memory newUriEvolved = "New Uri evolved";

        (string memory oldUriBase, string memory oldUriEvolved )= nftCollection.getURIs();

        vm.prank(owner);
        nftCollection.setUris(newUriBase, newUriEvolved);

        (string memory newUriBaseChanged, string memory newUriEvolvedChanged )= nftCollection.getURIs();

        assertEq(newUriBase, newUriBaseChanged);
        assertEq(newUriEvolved, newUriEvolvedChanged);

        assertNotEq(oldUriBase, newUriBaseChanged);
        assertNotEq(oldUriEvolved, newUriEvolvedChanged);
    }

    function testSetUrisRevertNotOwner() external {
        string memory newUriBase = "New Uri base";
        string memory newUriEvolved = "New Uri evolved";

        vm.prank(user1);
        vm.expectRevert();
        nftCollection.setUris(newUriBase, newUriEvolved);
    }

    function testSetNftPrice() external {
        uint256 newPrice = 1 ether;
        uint256 oldPrice = nftCollection.getNftPrice();

        assert(oldPrice == PRICE);

        vm.prank(owner);
        nftCollection.setNftPrice(newPrice);

        uint256 newPriceChanged = nftCollection.getNftPrice();

        assertNotEq(oldPrice, newPriceChanged);
        assertEq(newPrice, newPriceChanged);
    }

    function testSetNftPriceRevertNotOwner() external {
        uint256 newPrice = 1 ether;

        vm.prank(user1);
        vm.expectRevert();
        nftCollection.setNftPrice(newPrice);
    }

    function testSetMaxPerWallet() external {
        uint256 oldMaxPerWallet = nftCollection.getMaxPerWallet();
        uint256 newMaxPerWallet = oldMaxPerWallet - 2;
        
        assert(oldMaxPerWallet == MAX_PER_WALLET);

        vm.prank(owner);
        nftCollection.setMaxPerWallet(newMaxPerWallet);

        uint256 newMaxPerWalletChanged = nftCollection.getMaxPerWallet();

        assertNotEq(oldMaxPerWallet, newMaxPerWalletChanged);
        assertEq(newMaxPerWallet, newMaxPerWalletChanged);
    }

    function testSetMaxPerWalletRevertNotOwner() external {
        uint256 oldMaxPerWallet = nftCollection.getMaxPerWallet();
        uint256 newMaxPerWallet = oldMaxPerWallet - 2;
        
        assert(oldMaxPerWallet == MAX_PER_WALLET);

        vm.prank(user1);
        vm.expectRevert();
        nftCollection.setMaxPerWallet(newMaxPerWallet);
    }

    // Getter functions
    function testGetMaxSupply() external view {
        uint256 maxSupply = nftCollection.getMaxSupply();
        assert(MAX_SUPPLY == maxSupply);
    }

    function testGetMaxPerWallet() external view {
        uint256 maxPerWallet = nftCollection.getMaxPerWallet();
        assert(MAX_PER_WALLET == maxPerWallet);
    }

    function getNftPrice() external view {
        uint256 nftPrice = nftCollection.getNftPrice();
        assert(PRICE == nftPrice);
    }

    function getIsSoulbound() external view {
        bool soulbound = nftCollection.getIsSoulbound();
        assert(soulbound == SOULBOUND);
    }

    function getURIs() external view {
        string memory base = URI_BASE;
        string memory evolved = URI_EVOLVED;
        (string memory baseUri, string memory evolvedUri) = nftCollection.getURIs();

        assert(keccak256(abi.encodePacked(baseUri)) == keccak256(abi.encodePacked(base)));
        assert(keccak256(abi.encodePacked(evolvedUri)) == keccak256(abi.encodePacked(evolved)));
    }

    function testGetNftStatus() external {
        uint256 amountTokens = 2;
        uint256 price = PRICE * amountTokens;
        uint256 tokenIdToChangeStatus = 2;
        // starting token is 1 we must mint 2 and change one to check the status, it must be by default false.
        vm.startPrank(user1);
        nftCollection.mint{value: price}(amountTokens);
        nftCollection.toggleState(tokenIdToChangeStatus);
        vm.stopPrank();

        bool tokenId1Status = nftCollection.getNftStatus(tokenIdToChangeStatus - 1);
        bool tokenId2Status = nftCollection.getNftStatus(tokenIdToChangeStatus);

        assert(tokenId1Status == false);
        assert(tokenId2Status == true);
        assertNotEq(tokenId1Status, tokenId2Status);
    }

    // toggle function
    function testToggleState() external {
        uint256 amountTokens = 2;
        uint256 price = nftCollection.getNftPrice() * amountTokens;
        uint256 tokenIdToChangeStatus = 2;
        // starting token is 1 we must mint 2 and change one to check the status, it must be by default false.
        vm.startPrank(user1);
        nftCollection.mint{value: price}(amountTokens);
        nftCollection.toggleState(tokenIdToChangeStatus);
        vm.stopPrank();

        bool tokenId1Status = nftCollection.getNftStatus(tokenIdToChangeStatus - 1);
        bool tokenId2Status = nftCollection.getNftStatus(tokenIdToChangeStatus);

        assert(tokenId1Status == false);
        assert(tokenId2Status == true);
        assertNotEq(tokenId1Status, tokenId2Status);
    }

    function testToggleStateRevertTokenDoesNotExists() external {
        uint256 amountTokens = 1;
        uint256 price = PRICE * amountTokens;
        uint256 tokenIdToChangeStatus = 2;
        // starting token is 1 we must mint 2 and change one to check the status, it must be by default false.
        vm.startPrank(user1);
        nftCollection.mint{value: price}(amountTokens);
        vm.expectRevert(DerekNftCollection.DerekNftCollection__TokenDoesNotExists.selector);
        nftCollection.toggleState(tokenIdToChangeStatus);
        vm.stopPrank();
    }

    // Mint Function
    function testMint() external {
        uint256 quantityToMint = nftCollection.getMaxPerWallet();
        uint256 price = nftCollection.getNftPrice() * quantityToMint;
        uint256 user1Balance = user1.balance;
        uint256 nftBalance = nftCollection.balanceOf(user1);

        vm.startPrank(user1);
        nftCollection.mint{value: price}(quantityToMint);
        vm.stopPrank();

        uint256 user1BalanceAfter = user1.balance;
        uint256 nftBalanceAfter = nftCollection.balanceOf(user1);

        assert(user1BalanceAfter == (user1Balance - price));
        assertNotEq(nftBalance, nftBalanceAfter);
        assert(nftBalanceAfter == quantityToMint);

    }

    function testMintRevertSoldOut() external {
        uint256 quantityToMint = nftCollection.getMaxPerWallet(); // 6
        uint256 price = nftCollection.getNftPrice() * quantityToMint;
        vm.startPrank(owner);
        nftCollection.mint{value: price}(quantityToMint);
        vm.stopPrank();

        uint256 quantityToMintUser1 = MAX_SUPPLY - quantityToMint; // 10 - 6 = 4
        uint256 price2 = nftCollection.getNftPrice() * quantityToMintUser1;
        vm.prank(user1);
        nftCollection.mint{value: price2}(quantityToMintUser1);

        uint256 qtyMintUser2 = 2;
        uint256 price3 = nftCollection.getNftPrice() * qtyMintUser2;
        vm.prank(user2);
        vm.expectRevert(DerekNftCollection.DerekNftCollection__SoldOut.selector);
        nftCollection.mint{value: price3}(qtyMintUser2);

    }

    function testMintRevertIncorrectEthAmountHigher() external {
        uint256 quantityToMint = nftCollection.getMaxPerWallet();
        uint256 price = nftCollection.getNftPrice() * quantityToMint + 10000;
        vm.startPrank(user1);
        vm.expectRevert(DerekNftCollection.DerekNftCollection__IncorrectPrice.selector);
        nftCollection.mint{value: price}(quantityToMint);
        vm.stopPrank();
    }

    function testMintRevertIncorrectEthAmountLower() external {
        uint256 quantityToMint = nftCollection.getMaxPerWallet();
        uint256 price = nftCollection.getNftPrice() * quantityToMint - 10000;
        vm.startPrank(user1);
        vm.expectRevert(DerekNftCollection.DerekNftCollection__IncorrectPrice.selector);
        nftCollection.mint{value: price}(quantityToMint);
        vm.stopPrank();
    }

    function testMintRevertQtyIsHighetThanMaxAllowedPerWallet() external {
        uint256 quantityToMint = nftCollection.getMaxPerWallet() + 1;
        uint256 price = nftCollection.getNftPrice() * quantityToMint;
        vm.startPrank(user1);
        vm.expectRevert(DerekNftCollection.DerekNftCollection__CannotMintThatQuantityPerWallet.selector);
        nftCollection.mint{value: price}(quantityToMint);
        vm.stopPrank();
    }

    function testMintRevertQtyIsHighetThanMaxAllowedPerWalletHavingMinted4() external {
        uint256 quantityToMint = nftCollection.getMaxPerWallet() - 2; // 4
        uint256 price = nftCollection.getNftPrice() * quantityToMint;
        vm.startPrank(user1);
        nftCollection.mint{value: price}(quantityToMint);
        vm.stopPrank();

        uint256 quantityToMint2 = nftCollection.getMaxPerWallet(); // 6
        uint256 price2 = nftCollection.getNftPrice() * quantityToMint;
        vm.startPrank(user1);
        vm.expectRevert(DerekNftCollection.DerekNftCollection__CannotMintThatQuantityPerWallet.selector);
        nftCollection.mint{value: price2}(quantityToMint2);
        vm.stopPrank();
    }

    // withdraw function
    function testWithdrawBalanceRevertNoBalance() external {

        vm.prank(owner);
        vm.expectRevert(DerekNftCollection.NFTMock__NoBalanceInContract.selector);
        nftCollection.withdrawBalance();

    }

    function testWithdrawBalanceRevertNotTheOwner() external {

        vm.prank(user1);
        vm.expectRevert();
        nftCollection.withdrawBalance();
    }

    function testWithdrawBalance() external {
        uint256 amountOfNfts = nftCollection.getMaxPerWallet();
        uint256 amountEth = amountOfNfts * nftCollection.getNftPrice();

        vm.prank(user1);
        nftCollection.mint{value: amountEth}(amountOfNfts);

        uint256 ownerBalanceBefore = address(owner).balance;
        uint256 contractBalanceBefore = address(nftCollection).balance;

        vm.prank(owner);
        nftCollection.withdrawBalance();

        uint256 ownerBalanceAfter = address(owner).balance;
        uint256 contractBalanceAfter = address(nftCollection).balance;

        assert(contractBalanceBefore == amountEth);
        assert(contractBalanceAfter == 0);
        assertNotEq(contractBalanceBefore, contractBalanceAfter);
        assertNotEq(ownerBalanceBefore, ownerBalanceAfter);
    }

    // Soulbound function - In Script I have the soulbound function as true
    function testSoulboundFunctionRevertsCorrectly() external {
        // No transfer allowd in this function
        // We will try to mint with user1 and transfer tokenID 1 to user2
        uint256 quantityToMint = 1;
        uint256 price = nftCollection.getNftPrice() * quantityToMint;

        vm.startPrank(user1);
        nftCollection.mint{value: price}(quantityToMint);

        vm.expectRevert(DerekNftCollection.DerekNftCollection__SoulBoundNFT.selector);
        nftCollection.safeTransferFrom(user1, user2, quantityToMint);
        vm.stopPrank();
    }

    // TokenUri function
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    //     bool evolved = s_IsEvolved[tokenId];
        
    //     string memory baseURI = evolved ? s_UriStateEvolved : s_UriStateBase;

    //     return bytes(baseURI).length > 0 
    //         ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) 
    //         : "";
    // }

    function testTokenUriBase() external {
        uint256 amountTokens = 1;
        uint256 price = PRICE * amountTokens;
        uint256 tokenIdToCheckURI = 1;
        // starting token is 1 we must mint 2 and change one to check the status, it must be by default false.
        vm.startPrank(user1);
        nftCollection.mint{value: price}(amountTokens);
        vm.stopPrank();

        string memory baseUrl = string(abi.encodePacked(URI_BASE, amountTokens.toString(), ".json"));
        string memory tokenUri = nftCollection.tokenURI(tokenIdToCheckURI);

        assert(keccak256(abi.encodePacked(baseUrl)) == keccak256(abi.encodePacked(tokenUri)));
        
    }

    function testTokenUriEvolved() external {
        uint256 amountTokens = 1;
        uint256 price = PRICE * amountTokens;
        uint256 tokenIdToCheckURI = 1;
        // starting token is 1 we must mint 2 and change one to check the status, it must be by default false.
        vm.startPrank(user1);
        nftCollection.mint{value: price}(amountTokens);
        nftCollection.toggleState(tokenIdToCheckURI);
        vm.stopPrank();

        string memory evolvedUrl = string(abi.encodePacked(URI_EVOLVED, amountTokens.toString(), ".json"));
        string memory tokenUri = nftCollection.tokenURI(tokenIdToCheckURI);

        assert(keccak256(abi.encodePacked(evolvedUrl)) == keccak256(abi.encodePacked(tokenUri)));
        
    }

    function testTokenUriRevertsTokenDoesNotExists() external {
        uint256 amountTokens = 1;
        uint256 price = PRICE * amountTokens;
        uint256 tokenIdToCheckURI = 2;
        // starting token is 1 we must mint 2 and change one to check the status, it must be by default false.
        vm.startPrank(user1);
        nftCollection.mint{value: price}(amountTokens);
        vm.expectRevert();
        nftCollection.tokenURI(tokenIdToCheckURI);
        vm.stopPrank();
    }

}
