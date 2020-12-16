// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./YFBitcoin.sol";


// MasterChef is the master of YFBTC. He can make YFBTC and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once YFBTC is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 lastRewardBlock;  // Last block number that YFBTC distribution occurs.
        uint256 accYfbtcPerShare; // Accumulated YFBTC per share, times 1e12. See below.
        uint256 totalSupply;
    }

    // The YFBTC TOKEN!
    YFBitcoin public yfbtc;
    // Dev address.
    // Block number when bonus YFBTC period ends.
    uint256 public bonusEndBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when YFBTC mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        YFBitcoin _yfbtc,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        yfbtc = _yfbtc;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(IERC20 _lpToken) public onlyOwner {
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            lastRewardBlock: lastRewardBlock,
            accYfbtcPerShare: 0,
            totalSupply: 0
        }));
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
         uint256 difference = _to.sub(_from);
        if ( difference <=0 ){
            difference = 1;
        }
        if (_from >= startBlock && _to <= startBlock.add(1036800)){
            
            if (_to <= startBlock.add(172800)){
              uint256 rewardPerBlock = 26871140040000000;
              return rewardPerBlock.mul(difference);
            }
            else{
              uint256 rewardPerBlock = 8641973370000000;
              return rewardPerBlock.mul(difference);
            }
        }else if(_from >= startBlock && _to <= startBlock.add(2073600)){
           uint256 rewardPerBlock = 4320987650000000;
           return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(3110400)){
           uint256 rewardPerBlock = 2160493820000000;
           return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(4147200)){
          uint256 rewardPerBlock = 1080246910000000;
          return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(5184000)){
                uint256 rewardPerBlock = 540123450000000;
                return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(6220800)){
          uint256 rewardPerBlock = 270061720000000;
          return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(7257600)){
          uint256 rewardPerBlock = 135030860000000;
          return rewardPerBlock.mul(difference);
        }
        else if(_from >= startBlock && _to <= startBlock.add(8294400)){
          uint256 rewardPerBlock = 67515430000000;
          return rewardPerBlock.mul(difference);
        }
        return 0;
    }

    // View function to see pending YFBTC on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accYfbtcPerShare = pool.accYfbtcPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 yfbtcReward = getMultiplier(pool.lastRewardBlock, block.number);
            uint totalPoolsEligible = getEligiblePools();
            uint256 rewardPerPool = yfbtcReward.div(totalPoolsEligible);
            accYfbtcPerShare = accYfbtcPerShare.add(rewardPerPool.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see rewardPer YFBTC block  on frontend.
    function rewardPerBlock(uint256 _pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 accYfbtcPerShare = pool.accYfbtcPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 yfbtcReward = getMultiplier(pool.lastRewardBlock, block.number);
            uint totalPoolsEligible = getEligiblePools();
            uint256 rewardPerPool = yfbtcReward.div(totalPoolsEligible);
            accYfbtcPerShare = accYfbtcPerShare.add(rewardPerPool.mul(1e12).div(lpSupply));
        }
        return accYfbtcPerShare;
    }


    function getEligiblePools() internal view returns(uint){
        uint totalPoolsEligible = 0;
        uint256 length = poolInfo.length;

        // Reward will only be assign to pools when they the staked balance is > 0  
        for (uint256 pid = 0; pid < length; ++pid) {
            if( poolInfo[pid].totalSupply > 0){
              totalPoolsEligible = totalPoolsEligible.add(1);
            }
        }
        return totalPoolsEligible;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 yfbtcReward = getMultiplier(pool.lastRewardBlock, block.number);
        if ( yfbtcReward <= 0 ){
          return;
        }
        yfbtc.mint(address(this), yfbtcReward);
        uint totalPoolsEligible = getEligiblePools();
        uint256 rewardPerPool = yfbtcReward.div(totalPoolsEligible);
        pool.accYfbtcPerShare = pool.accYfbtcPerShare.add(rewardPerPool.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for YFBTC allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeYfbtcTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            pool.totalSupply = pool.totalSupply.add(_amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accYfbtcPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accYfbtcPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeYfbtcTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.totalSupply = pool.totalSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accYfbtcPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }
  
   // let user exist in case of emergency
   function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        pool.totalSupply = pool.totalSupply.sub(amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe yfbtcReward transfer function, just in case if rounding error causes pool to not have enough YFBTC.
    function safeYfbtcTransfer(address _to, uint256 _amount) internal {
        uint256 yfbtcBal = yfbtc.balanceOf(address(this));
        if (_amount > yfbtcBal) {
            yfbtc.transfer(_to, yfbtcBal);
        } else {
            yfbtc.transfer(_to, _amount);
        }
    }
}