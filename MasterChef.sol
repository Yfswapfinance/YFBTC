pragma solidity 0.6.12;

import "Ownable.sol";
contract MasterChef is Ownable {
    using SafeMath for uint256;
    
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    
        // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 totalSupply;      // supply of the pool
        uint256 lastRewardBlock;  // Last block number that yfbtc distribution occurs.
        uint256 accYfbtcPerShare; // Accumulated SUSHIs per share, times 1e12. See below.

    }
    
    // 1-min = 4 blocks
    // 1-hour = 240 blocks
    // 1-day = 5760 blocks
    // 1-month = 172800 blocks
    // 6-months = 1036800 blocks

    address public devAddress;
    
    // The YFEBitcoin TOKEN!
    YFEBitcoin public yfbtc;
    
    UniSwapMasterchef public uniSwapMasterchef;
    
    // The block number when YFBTC mining starts.
    uint256 public startBlock;
    
    // The block number when YFBTC mining Stops.
    uint256 public endBlock;
    
    // Block number when bonus YFBTC period ends.
    uint256 public bonusEndBlock;

    // total supply distributed per year
    uint256 constantSupply = 17850 * 10 ** 18;
    
    // bonus supply going to distributed for first month 
    uint256 bonusSupply = 3150 * 10 ** 18;
    
    // Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        YFEBitcoin _yfbtc,
        UniSwapMasterchef _uniSwapMasterChef,
        address _devAddress,
        uint256 _startBlock) public{
          yfbtc = _yfbtc;
          uniSwapMasterchef = _uniSwapMasterChef;
          devAddress  = _devAddress;
          startBlock = _startBlock;
          endBlock = startBlock.add(23040);
          bonusEndBlock = startBlock.add(7200);
        }
    // Let the owner set the funding address from developers
    function setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }
    
    // Let the owner set the block number when the reward distribution get started
    function setStartBlock(uint256 _startBlock) public onlyOwner{
        startBlock = _startBlock;
    }
    
    // Let the owner add pool for farming
    function add(IERC20 _lpToken, uint256 _supply) public onlyOwner{
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            totalSupply: _supply,
            lastRewardBlock: block.number,
            accYfbtcPerShare: 0
        }));
    }
    
    // return reward coins base on time period. this function holds 4 years reward coins 
    function getReward(uint256 _from, uint256 _to) internal view returns (uint256){
        

        if (_from >= startBlock && _to <= startBlock.add(1036800)){
            
            if (_to <= startBlock.add(172800)){
                return constantSupply.div(2).add(bonusSupply).div(1036800);
            }
            else{
                return constantSupply.div(2);
            }
        }else if(_from >= startBlock && _to <= startBlock.add(2073600)){
            return constantSupply.div(4);
        }
        else if(_from >= startBlock && _to <= startBlock.add(3110400)){
            return constantSupply.div(6);
        }
        else if(_from >= startBlock && _to <= startBlock.add(4147200)){
            return constantSupply.div(8);
        }
        else if(_from >= startBlock && _to <= startBlock.add(5184000)){
            return constantSupply.div(10);
        }
        else if(_from >= startBlock && _to <= startBlock.add(6220800)){
            return constantSupply.div(12);
        }
        else if(_from >= startBlock && _to <= startBlock.add(7257600)){
            return constantSupply.div(14);
        }
        else if(_from >= startBlock && _to <= startBlock.add(8294400)){
            return constantSupply.div(16);
        }
    }
    
    // update pool and mint coins called Whenever deposit or withdrawal occur
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        
        if (pool.totalSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        
        uint256 totalPoolReward = getReward(pool.lastRewardBlock, block.number);
        yfbtc.mint(address(this), totalPoolReward);
        pool.accYfbtcPerShare = pool.accYfbtcPerShare.add(totalPoolReward).mul(1e12).div(pool.totalSupply);
        pool.lastRewardBlock = block.number;
    }
    
    // let the user stake coins
    function deposit(uint256 _pid, address _token,
        uint _amountTokenDesired,
        uint _amountTokenMin,
        uint _amountETHMin,
        address _to,
        uint _deadline) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
         if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
            yfbtc.transfer(msg.sender, pending);
        }
        pool.totalSupply = pool.totalSupply.add(_amountETHMin);
        uniSwapMasterchef.addLiquidityETH(_token, _amountTokenDesired, _amountTokenMin, _amountETHMin, _to, _deadline);
        user.amount = user.amount.add(_amountETHMin);
        user.rewardDebt = user.amount.mul(pool.accYfbtcPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amountETHMin);
    }
    
    // let the user withdrawal staked coins
    function withdraw(uint256 _pid, address _token,
        uint _liquidity,
        uint _amountTokenMin,
        uint _amountETHMin,
        address _to,
        uint _deadline) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amountETHMin, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
        yfbtc.transfer(msg.sender, pending);
        uniSwapMasterchef.removeLiquidityETH(_token, _liquidity, _amountTokenMin, _amountETHMin, _to, _deadline);
        user.amount = user.amount.sub(_amountETHMin);
        user.rewardDebt = user.amount.mul(pool.accYfbtcPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amountETHMin);
    }
    
}