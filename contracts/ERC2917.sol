//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './interface/IERC2917.sol';
import './libraries/Upgradable.sol';
import './libraries/SafeMath.sol';
import './libraries/ReentrancyGuard.sol';
import './ERC20.sol';

/*
    The Objective of ERC2917 Demo is to implement a decentralized staking mechanism, which calculates users' share
    by accumulating productiviy * time. And calculates users revenue from anytime t0 to t1 by the formula below:

        user_accumulated_productivity(time1) - user_accumulated_productivity(time0)
       _____________________________________________________________________________  * (gross_product(t1) - gross_product(t0))
       total_accumulated_productivity(time1) - total_accumulated_productivity(time0)

*/
contract ERC2917Impl is IERC2917, ERC20, UpgradableProduct, UpgradableGovernance, ReentrancyGuard {
    using SafeMath for uint;

    uint public mintCumulation;
    uint public usdPerBlock;
    uint public lastRewardBlock;
    uint public totalProductivity;
    uint public accAmountPerShare;

    struct UserInfo {
        uint amount;     // How many LP tokens the user has provided.
        uint rewardDebt; // Reward debt. 
    }

    mapping(address => UserInfo) public users;

    // creation of the interests token.
    constructor(uint _interestsRate) ERC20() UpgradableProduct() UpgradableGovernance() {
        usdPerBlock = _interestsRate;
    }

    // External function call
    // This function adjust how many token will be produced by each block, eg:
    // changeAmountPerBlock(100)
    // will set the produce rate to 100/block.
    function changeInterestRatePerBlock(uint value) external override requireGovernor returns (bool) {
        uint old = usdPerBlock;
        require(value != old, 'AMOUNT_PER_BLOCK_NO_CHANGE');

        usdPerBlock = value;

        emit InterestRatePerBlockChanged(old, value);
        return true;
    }

    function enter(address account, uint256 amount) external override returns (bool) {
        require(this.deposit(account, amount), "INVALID DEPOSIT");
        return increaseProductivity(account, amount);
    }

    function exit(address account, uint256 amount) external override returns (bool) {
        require(this.withdrawal(account, amount), "INVALID WITHDRAWAL");
        return decreaseProductivity(account, amount);
    }

    // Intercept erc20 transfers 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(decreaseProductivity(from, amount), "INVALID DEC PROD");
        require(increaseProductivity(to, amount), "INVALID INC PROD");
    }

    // Update reward variables of the given pool to be up-to-date.
    function update() internal 
    {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalProductivity == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number.sub(lastRewardBlock);

        uint256 reward = multiplier.mul(usdPerBlock);
        
        balanceOf[address(this)] = balanceOf[address(this)].add(reward);

        totalSupply = totalSupply.add(reward);

        accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        lastRewardBlock = block.number;

    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function increaseProductivity(address user, uint value) internal returns (bool) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');

        UserInfo storage userInfo = users[user];
        update();
        if (userInfo.amount > 0) {
            uint pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
            _transfer(address(this), user, pending);
            mintCumulation = mintCumulation.add(pending);
        }

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        emit ProductivityIncreased(user, value);
        return true;
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function decreaseProductivity(address user, uint value) internal returns (bool) {
        require(value > 0, 'INSUFFICIENT_PRODUCTIVITY');
        
        UserInfo storage userInfo = users[user];
        require(userInfo.amount >= value, "WASABI: FORBIDDEN");
        update();
        uint pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
        _transfer(address(this), user, pending);
        mintCumulation = mintCumulation.add(pending);
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);

        emit ProductivityDecreased(user, value);
        return true;
    }

    // =========================================== views

    // It returns the interests that callee will get at current block height.
    function take() external override view returns (uint) {
        UserInfo storage userInfo = users[msg.sender];
        uint _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint multiplier = block.number.sub(lastRewardBlock);
            uint reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        }
        return userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
    }

    function takeWithAddress(address user) external view returns (uint) {
        UserInfo storage userInfo = users[user];
        uint _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint multiplier = block.number.sub(lastRewardBlock);
            uint reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        }
        return userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
    }

    // Returns how much a user could earn plus the giving block number.
    function takeWithBlock() external override view returns (uint, uint) {
        UserInfo storage userInfo = users[msg.sender];
        uint _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint multiplier = block.number.sub(lastRewardBlock);
            uint reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        }
        return (userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(userInfo.rewardDebt), block.number);
    }

    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function mint() external override nonReentrant returns (uint) {
        return 0;
    }

    // Returns how many productivity a user has and global has.
    function getProductivity(address user) external override view returns (uint, uint) {
        return (users[user].amount, totalProductivity);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() external override view returns (uint) {
        return accAmountPerShare;
    }

    function getStatus() 
    external 
    override
    view 
    returns (uint, uint, uint, uint) 
    {
        return (lastRewardBlock, totalProductivity, accAmountPerShare, mintCumulation);
    }
}
