<div align="center">
  <h1>🎨 Dynamic Soulbound NFT Collection</h1>
  <p><b>A highly optimized, state-toggling ERC721A implementation with optional Soulbound mechanics.</b></p>
</div>

## 📖 About the Project

The **Derek NFT Collection** is a production-ready Web3 Smart Contract project built with **Solidity `0.8.30`** and thoroughly tested using the **Foundry** framework. At its core, the project provides a highly optimized, feature-rich ERC721A token contract that introduces dynamic metadata and non-transferable (Soulbound) capabilities.

This architecture is ideal for projects requiring dynamic NFT mechanics (such as evolving game characters or tiered membership passes) and strict community binding where tokens cannot be traded on secondary markets once minted. 

**Key Technical Highlights:**
* **Solidity `0.8.30`:** Leveraging the latest compiler features for maximum security and gas efficiency.
* **ERC721A Implementation:** Utilizes Azuki's highly optimized standard for minting multiple NFTs at a fraction of the standard gas cost.
* **OpenZeppelin Integration:** Implements `Ownable` for access control and `ReentrancyGuard` to secure payable minting functions.
* **Dynamic On-Chain States:** Users can directly interact with the contract to toggle their NFT's metadata between a "Base" and "Evolved" state.
* **Foundry Framework:** Backed by a comprehensive test suite (`DerekNftCollectionTest.t.sol`) validating state transitions, strict soulbound reversion limits, and access controls.

---

## ⚙️ How It Works

The `DerekNftCollection` contract is initialized with core parameters including supply caps, pricing, URIs for two distinct metadata states, and a boolean determining if the collection is Soulbound. 

When a user mints a token, they pay the exact configured price. By default, the token points to the "Base" URI. The token owner can call `toggleState()` to switch their specific token's metadata to the "Evolved" URI. If the `i_soulbound` flag is set to true during deployment, the internal `_beforeTokenTransfers` hook will aggressively revert any transfer attempts between wallets, locking the asset strictly to the minter.

### Architecture Diagram

![Project Diagram](./images/diagram.png)

### Core Component File Paths
* [`DerekNftCollection.sol`](./src/DerekNftCollection.sol) - Main Application Logic
* [`DerekNftCollectionScript.s.sol`](./script/DerekNftCollectionScript.s.sol) - Deployment Script
* [`DerekNftCollectionTest.t.sol`](./test/DerekNftCollectionTest.t.sol) - Comprehensive Test Suite

---

## 💻 Technical Docs

The primary interaction points of the application handle the optimized minting process, the dynamic state toggling, and the strict transfer hooks. 

### mint
Allows users to mint up to the maximum allowed per wallet in a single, gas-efficient transaction using `_safeMint` from the ERC721A standard. Reverts on incorrect ether values or supply limits.

```solidity
    function mint(uint256 _quantity) external payable nonReentrant {
        uint256 balanceOfUser = balanceOf(msg.sender);
        uint256 maxPerWallet = s_MaxPerWallet;
        
        if (_quantity > maxPerWallet || (_quantity + balanceOfUser) > maxPerWallet) revert DerekNftCollection__CannotMintThatQuantityPerWallet();
        if (msg.value != (s_NftPrice * _quantity)) revert DerekNftCollection__IncorrectPrice();
        if ((totalSupply() + _quantity) > i_MaxSupply) revert DerekNftCollection__SoldOut();
        
        _safeMint(msg.sender, _quantity);
        emit MintNFT(msg.sender, _quantity);
    }
```

### toggleState
Empowers the NFT owner to evolve or devolve their token. This simply flips a boolean mapped to the tokenId, which dynamically alters the output of the `tokenURI` function.

```Solidity
    function toggleState(uint256 tokenId) external {
        if (!_exists(tokenId)) revert DerekNftCollection__TokenDoesNotExists();
        if (ownerOf(tokenId) != msg.sender) revert("Not your token");
        
        s_IsEvolved[tokenId] = !s_IsEvolved[tokenId];
    }
```

### tokenURI
Overrides the standard ERC721 URI function to read the current boolean state of the token, seamlessly pointing marketplaces and dApps to the correct JSON metadata.

```Solidity
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        bool evolved = s_IsEvolved[tokenId];
        
        string memory baseURI = evolved ? s_UriStateEvolved : s_UriStateBase;
        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) 
            : "";
    }
```

### _beforeTokenTransfers
The core security hook for the Soulbound functionality. If initialized as true, any token movement outside of standard minting (address 0 to user) is blocked.

```Solidity
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
```

🚀 Execution Example
Here is a step-by-step example of how a user interacts with the DerekNftCollection contract:

- Step 1: Deployment & Configuration
The contract is deployed by the Owner using the DeployNftCollectionScript. During deployment, the Soulbound toggle is set to true, the price is set to 0.5 ether, and both Base and Evolved IPFS URIs are established.

- Step 2: Minting
A User wants 2 NFTs. They call mint(2) and send exactly 1.0 ether. Because of the ERC721A implementation, they receive Token ID 1 and Token ID 2 for remarkably low gas.

- Step 3: State Evolution
The User decides to evolve Token ID 2. They call toggleState(2). The contract verifies they are the owner and flips the boolean. Now, querying tokenURI(2) returns the Evolved IPFS link, while tokenURI(1) continues to return the Base IPFS link.

- Step 4: Soulbound Restriction
The User attempts to sell Token ID 1 on OpenSea. When the marketplace attempts to transfer the token, the _beforeTokenTransfers hook detects the transaction is between two non-zero addresses and reverts the transaction with DerekNftCollection__SoulBoundNFT().

- Step 5: Treasury Withdrawal
The Owner calls withdrawBalance() (protected by nonReentrant and onlyOwner), safely moving the accumulated 1.0 ether out of the contract and into the project treasury.

⬆️ Installation
Ensure you have Foundry installed on your machine. Install the required project dependencies using the command below:
```Bash
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std chiru-labs/ERC721A
```

🧪 Testing
```Bash
forge test
```

📊 Coverage
```Bash
forge coverage
```

📜 Contract Addresses
- [Deploy and paste your contract address here]