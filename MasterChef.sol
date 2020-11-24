// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "IUniSwapV2Factory.sol";
import "UniswapV2Pair.sol";
import "Ownable.sol";
import "SafeMath1.sol";
import "YFBTC.sol";


    // 1-min = 4 blocks
    // 1-hour = 240 blocks
    // 1-day = 5760 blocks
    // 1-month = 172800 blocks
    // 6-months = 1036800 blocks

contract MasterChef is Ownable{
    using SafeMath for *;
     struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt;
    }
    
    // live net token0 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // livenet factory 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    
    
    // kovan token0 0xd0a1e359811322d97991e03f863a0c30c2cf029c
    // kovan token1 0x551733cf73465a007BD441d0A1BBE1b30355B28A
    // kovan factory 0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f
    
    uint256 lastPrice = 0;
    
    
    uint public constant PERIOD = 24 hours;
    
    // holds the WETH address
    address public  token0;

    // holds the YFBTC address
    address public  token1;

    // hold factory address that will be used to fetch pair address
    address public  factory;

    // The YFBTC TOKEN!
    YFBitcoin public yfbtc;
    
    IERC20 uniV2;

    // hold the supply of Uni_v2 tokens
    uint256 public uniV2Supply = 0;
    
    // hold the total undistributed Reward of YFBTC TOKEN
    uint256 public totalReward = 0;
    
    // hold the block number of last rewarded block
    uint256 lastRewardBlock = 0;
    
    // The block number when YFBTC mining starts.
    uint256 public startBlock;
    
    // The block number when YFBTC mining Stops.
    uint256 public endBlock;

    // Block number when bonus YFBTC period ends.
    uint256 public bonusEndBlock;
    
    
    uint public price0CumulativeLast;
    
    uint public price1CumulativeLast;

    // block time of last update
    uint32 public blockTimestampLast;
    
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    
    
    constructor(
        YFBitcoin _yfbtc,
        IERC20 _uniV2,
        address _factory, 
        address _token0,
        address _token1,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        yfbtc = _yfbtc;
        uniV2 = _uniV2;
        factory = _factory;
        token0 = _token0;
        token1 = _token1;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);
        (uint112 reserve0, uint112 reserve1, uint32 blockTime) = UniswapV2Pair(pairAddress).getReserves(); // gas savings
        // price0CumulativeLast = UniswapV2Pair(pairAddress).price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        // price1CumulativeLast = UniswapV2Pair(pairAddress).price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        blockTimestampLast = blockTime;
        lastPrice = reserve1.div(reserve0);
        require(reserve0 != 0 && reserve1 != 0, 'ORACLE: NO_RESERVES'); // ensure that there's liquidity in the pair

    }
    
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }
    
    function setTransferFee(uint256 _fee) public onlyOwner {
        require(_fee > 0 && _fee < 1000, "YFBTC: fee should be between 0 and 10");
        yfbtc.setTransferFee(_fee);
    }
    
    function mint(address _to, uint256 _amount) public onlyOwner {
        yfbtc.mint(_to, _amount);
    }
    
    function update() public returns(bool) {
        
        uint32 blockTimestamp = currentBlockTimestamp();
        address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, 'ORACLE: PERIOD_NOT_ELAPSED');
        
        (uint112 _reserve0, uint112 _reserve1, ) = UniswapV2Pair(pairAddress).getReserves(); // gas savings
        
        uint256 curretPrice = _reserve1.div(_reserve0);

        uint256 change = curretPrice.sub(lastPrice).div(lastPrice);
        lastPrice = curretPrice;
        blockTimestampLast = blockTimestamp;
        
        if ( change <= 5 * 10 ** 17)
        return false;
        
        return true;
    }
    
    
     // return reward coins base on time period. this function holds 4 years reward coins 
    function getReward(uint256 _from, uint256 _to) internal view returns (uint256){
        uint256 difference = _to.sub(_from);
        if ( difference <=0 ){
            difference = 1;
        }
        if (_from >= startBlock && _to <= startBlock.add(1036800)){
            
            if (_to <= startBlock.add(172800)){
                return 26871140040000000 * difference;
            }
            else{
                return 8641973370000000 * difference;
            }
        }else if(_from >= startBlock && _to <= startBlock.add(2073600)){
            return 4320987650000000 * difference;
        }
        else if(_from >= startBlock && _to <= startBlock.add(3110400)){
            return 2160493820000000 * difference;
        }
        else if(_from >= startBlock && _to <= startBlock.add(4147200)){
            return 1080246910000000 * difference;
        }
        else if(_from >= startBlock && _to <= startBlock.add(5184000)){
            return 540123450000000 * difference;
        }
        else if(_from >= startBlock && _to <= startBlock.add(6220800)){
            return 270061720000000 * difference;
        }
        else if(_from >= startBlock && _to <= startBlock.add(7257600)){
            return 135030860000000 * difference;
        }
        else if(_from >= startBlock && _to <= startBlock.add(8294400)){
            return 67515430000000 * difference;
        }
        return 0;
    }
    
    // this function will dispatch user pending reward
    function dispatchDeward() internal {
        UserInfo storage user = userInfo[msg.sender];
        
        if (user.amount > 0) {
            // user already have depoited token so we need to distribute pending reward
            uint256 yfbtcPerShare = totalReward.div(uniV2Supply);

            uint256 rewardToDispatch = yfbtcPerShare * user.amount;

            if(rewardToDispatch > 0) {
                yfbtc.transfer(msg.sender, rewardToDispatch);
                totalReward = totalReward.sub(rewardToDispatch);
                user.rewardDebt = user.rewardDebt.add(rewardToDispatch);
            }
        }
    }
    
    // View function to see pending YFBTC on frontend.
    function pendingReward() external view returns (uint256) {
        UserInfo storage user = userInfo[msg.sender];
      
        uint256 totalPoolReward = getReward(lastRewardBlock, block.number);
        uint256 yfbtcPerShare = totalPoolReward.div(uniV2Supply);

        return yfbtcPerShare * user.amount;
    }

    // mint new yfbtc tokens for reward Distribution
    function mintReward() internal{
        bool doMint = update();
        
        if ( doMint ){
        uint256 rewardToMint = getReward(lastRewardBlock, block.number);
        
        if (rewardToMint > 0 ){
        yfbtc.mint(address(this), rewardToMint);
        totalReward = totalReward.add(rewardToMint);
        lastRewardBlock = block.number;
        }
        }
    }
    
    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        
        // dispatch user pending reward if any
        dispatchDeward();

        user.amount = user.amount.add(_amount);
        uniV2Supply = uniV2Supply.add(_amount);

        // mint new tokens
        mintReward();
        

        emit Deposit(msg.sender, _amount);
    }
    
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        
        require(user.amount >= _amount, "withdraw: Insufficent balance");

        // dispatch user pending reward if any
        dispatchDeward();
        
         user.amount = user.amount.sub(_amount);
         
        // mint new tokens
        mintReward();
        
         // transfer lp tokens back
         uniV2.transfer(address(msg.sender), _amount);
        
        emit Withdraw(msg.sender, _amount);
    }
}