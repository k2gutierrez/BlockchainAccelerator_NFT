// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {DerekNftCollection} from "../src/DerekNftCollection.sol";

contract DeployNftCollectionScript is Script {
    DerekNftCollection public nftCollection;

    // function setUp() public {}

    function run() public returns(DerekNftCollection) {
        bool _soulbound = true;
        address _owner = makeAddr("owner");
        string memory _UriBase = "ipfs://fewfgwGRBase/";
        string memory _UriEvolved = "ipfs://fewfgwGREvolved/";
        string memory _name = "Some NFT";
        string memory _symbol = "SNFT";
        uint256 _maxSupply = 10;
        uint256 _maxPerWallet = 6;
        uint256 _price = .5 ether;

        vm.startBroadcast();

        nftCollection = new DerekNftCollection(_soulbound, _owner, _UriBase, _UriEvolved, _name, _symbol, _maxSupply, _maxPerWallet, _price);

        vm.stopBroadcast();
        return nftCollection;
    }
}

// forge script script/DerekNftCollectionScript.s.sol:DeployNftCollection --rpc-url https://arb1.arbitrum.io/rpc --broadcast --verify