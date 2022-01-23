// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTStaker is Ownable, ReentrancyGuard {

    uint internal constant BITSHIFT_OWNER = 12;

    uint internal constant BITWIDTH_TOKEN_ID = 15;

    uint internal constant BITWIDTH_BLOCK_NUM = 31;

    uint internal constant BITMASK_BLOCK_NUM = (1 << BITWIDTH_BLOCK_NUM) - 1;

    uint internal constant BITWIDTH_STAKE = (BITWIDTH_TOKEN_ID + BITWIDTH_BLOCK_NUM);

    uint internal constant BITMASK_STAKE = (1 << BITWIDTH_STAKE) - 1;

    uint internal constant BITMOD_STAKE = (256 / BITWIDTH_STAKE);

    uint internal constant BITPOS_NUM_STAKED = BITMOD_STAKE * BITWIDTH_STAKE;

    uint internal constant BITMASK_STAKES = (1 << BITPOS_NUM_STAKED) - 1;
    
    uint internal constant BITWIDTH_RATE = 4;

    uint internal constant BITMOD_RATE = (256 / BITWIDTH_RATE);

    uint internal constant BITMASK_RATE = (1 << BITWIDTH_RATE) - 1;

    uint internal constant DEFAULT_RATE = 5;

    bool internal constant USE_BLOCKNUM_MOCK = true; // set to false for production!
    
    uint public constant STAKED_BLOCK_MIN = 50000;

    uint public harvestBaseRate;

    uint public blockNumMock;

    address public immutable coin;

    address public immutable nft;

    mapping(uint => uint) internal vault;

    mapping(uint => uint) internal nftRates;

    uint public distributed;

    constructor() {
        // Please change accordingly for production.
        // Remember to fund the contract with the coin after deploying.
        nft = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        coin = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        // 1000000 * 1000000000000000000 * 60 / 100 / (20000 * 5 * 86400 * 365 / 13)
        harvestBaseRate = 2500000000000; // Please set accordingly.
    }
    
    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function setNFTRates(uint[] memory _indices, uint[] memory _rates) external onlyOwner {
        uint n = _indices.length;
        require(n == _rates.length && n > 0, "Out of bounds");
        for (uint i = 0; i < n; ++i) { 
            nftRates[_indices[i]] = _rates[i];
        }
    }

    function setHarvestBaseRate(uint _harvestBaseRate) external onlyOwner {
        harvestBaseRate = _harvestBaseRate;
    }

    function coinBalance() external view returns (uint) {
        return IERC20(coin).balanceOf(address(this));
    }

    function withdrawERC20(address _erc20) public onlyOwner {
        uint256 amount = IERC20(_erc20).balanceOf(address(this));
        IERC20(_erc20).transfer(msg.sender, amount);
    }

    function withdrawCoin() external onlyOwner {
        withdrawERC20(coin);   
    }

    function setBlockNum(uint _blockNum) external onlyOwner {
        blockNumMock = _blockNum;
    }

    function stake(uint[] memory _tokenIds) external nonReentrant {
        require(nft != address(0), "Staking not opened");
        uint n = _tokenIds.length;
        require(n > 0, "Please stake at least 1 token.");
        uint o = uint256(uint160(msg.sender)) << BITSHIFT_OWNER;
        uint f = vault[o];
        uint m = f >> BITPOS_NUM_STAKED;

        uint j = m;

        vault[o] = f ^ ((m ^ (m + n)) << BITPOS_NUM_STAKED);

        uint blockNumCurr = USE_BLOCKNUM_MOCK ? blockNumMock : block.number;
        for (uint i = 0; i < n; ++i) {
            uint tokenId = _tokenIds[i];
            
            // Transfer NFT from owner to contract.
            IERC721(nft).transferFrom(msg.sender, address(this), tokenId);

            uint q = (j / BITMOD_STAKE) | o;
            uint r = (j % BITMOD_STAKE) * BITWIDTH_STAKE;
            uint s = (tokenId << BITWIDTH_BLOCK_NUM) | blockNumCurr;
            vault[q] |= (s << r);
            ++j;
        }
    }

    function staked(address _owner) external view returns (uint[] memory) {
        uint o = uint256(uint160(_owner)) << BITSHIFT_OWNER;
        uint f = vault[o];
        uint m = f >> BITPOS_NUM_STAKED;

        uint[] memory a = new uint[](m);
        for (uint j = 0; j < m; ++j) {
            uint q = (j / BITMOD_STAKE) | o;
            uint r = (j % BITMOD_STAKE) * BITWIDTH_STAKE;
            uint s = (vault[q] >> r) & BITMASK_STAKE;
            a[j] = s >> BITWIDTH_BLOCK_NUM;
        }
        return a;
    }

    function unstake(uint[] memory _tokenIndices, uint _numStaked) external nonReentrant {
        uint o = uint256(uint160(msg.sender)) << BITSHIFT_OWNER;
        uint f = vault[o];
        uint m = f >> BITPOS_NUM_STAKED;      
        require(m == _numStaked, "Number staked mismatch.");
        uint n = _tokenIndices.length;
        require(n > 0, "Please unstake at least 1 token.");
        require(m >= n, "Index out of bounds.");

        vault[o] = f ^ ((m ^ (m - n)) << BITPOS_NUM_STAKED);
        uint p = 2147483647;
        for (uint i = 0; i < n; ++i) {
            uint j = _tokenIndices[i];
            require(j < m, "Index out of bounds.");
            require(j < p, "Indices out of order.");
            uint q = (j / BITMOD_STAKE) | o;
            uint r = (j % BITMOD_STAKE) * BITWIDTH_STAKE;
            uint s = (vault[q] >> r) & BITMASK_STAKE;
            
            // Transfer NFT from contract to owner.
            uint tokenId = s >> BITWIDTH_BLOCK_NUM;
            
            IERC721(nft).transferFrom(address(this), msg.sender, tokenId);

            --m;
            uint u = (m / BITMOD_STAKE) | o;
            uint v = (m % BITMOD_STAKE) * BITWIDTH_STAKE;
            uint w = (vault[u] >> v) & BITMASK_STAKE;
            vault[q] ^= ((s ^ w) << r);
            vault[u] ^= (w << v);
            p = j;
        }
    }

    function harvest() external nonReentrant returns (uint) {
        uint o = uint256(uint160(msg.sender)) << BITSHIFT_OWNER;
        uint f = vault[o];
        uint m = f >> BITPOS_NUM_STAKED;
        uint amount = 0;
        
        uint blockNumCurr = USE_BLOCKNUM_MOCK ? blockNumMock : block.number;
        for (uint j = 0; j < m; ++j) {
            uint q = (j / BITMOD_STAKE) | o;
            uint r = (j % BITMOD_STAKE) * BITWIDTH_STAKE;
            uint s = (vault[q] >> r) & BITMASK_STAKE;
            
            uint blockNum = s & BITMASK_BLOCK_NUM;
            uint tokenId = s >> BITWIDTH_BLOCK_NUM;

            if (blockNum + STAKED_BLOCK_MIN <= blockNumCurr) {
                uint blockNumDiff = blockNumCurr - blockNum;
                uint u = (tokenId / BITMOD_RATE);
                uint v = (tokenId % BITMOD_RATE) * BITWIDTH_RATE;
                uint rate = 0;

                rate = (nftRates[u] >> v) & BITMASK_RATE;
                if (rate == 0) {
                    rate = DEFAULT_RATE;
                }
                
                amount += rate * blockNumDiff;
                uint w = (tokenId << BITWIDTH_BLOCK_NUM) | blockNumCurr;
                vault[q] ^= ((s ^ w) << r);
            }            
        }
        amount *= harvestBaseRate;

        uint256 balance = IERC20(coin).balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }

        require(amount > 0, "Nothing to harvest.");

        distributed += amount;

        IERC20(coin).transfer(msg.sender, amount);
        return amount;
    }
}
