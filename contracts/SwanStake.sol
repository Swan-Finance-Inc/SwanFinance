pragma solidity 0.5.16;

interface ERC20 {

    function transferFrom (address,address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function transfer (address, uint256) external returns (bool);

}

contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed _to);

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Caller is Not the OWNER");
        _;
    }

    function transferOwnership(address newOwnerAddress) external onlyOwner {
        require(newOwnerAddress != address(0), "Invalid Address: New owner is the zero address");
        newOwner = newOwnerAddress;
    }
    function acceptOwnership() external {
        require(msg.sender == newOwner,"Caller is not the selected Owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
      require(!paused,"Contract is Paused");
      _;
    }

    modifier whenPaused() {
      require(paused,"Contract is Not Paused");
      _;
    }

    function pause() onlyOwner whenNotPaused external {
      paused = true;
      emit Pause();
    }

    function unpause() onlyOwner whenPaused external {
      paused = false;
      emit Unpause();
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}

///@title Swan Staking Contract
contract SwanStake is Pausable{

    using SafeMath for uint256;
    address public swanTokenAddress;
    uint256 public currentPrice;

    constructor(address swanToken) public Owned(msg.sender) {
    require (swanToken != address(0),"Token Address cannot be a Zero Address");
    swanTokenAddress = swanToken;
    currentPrice = 1 ether;
  }
  // @notice Stores STAKE ACCOUNT details of the USER
    struct StakeAccount{
      uint256 stakedAmount;
      uint256 time;
      uint256 interestRate;
      bool unstaked;
    }
  // @notice Stores INTEREST ACCOUNT details of the USER
    struct InterestAccount 
    {
    uint256 amount;
    uint256 time;
    uint256 interestRate;
    uint256 interestPayouts;
    uint256 timeperiod;
    bool withdrawn;
    }

  mapping(address => bool) public isStaker;
  mapping(address => uint256) public userTotalStakes;
  mapping (address => uint256) public interestAccountNumber;
  mapping(address => StakeAccount) public stakeAccountDetails;
  mapping(address=>mapping(uint256 => uint256)) public lastPayoutCall;
  mapping(address => mapping(uint256 => uint256)) public totalPoolRewards;
  mapping(address => mapping(uint256 => bool)) public checkCycle;
  mapping(address => mapping (uint256 => InterestAccount)) public interestAccountDetails;


  //  @dev emitted whenever user stakes tokens in the Stake Account
  event staked(address indexed _user,uint256 _amount,uint256 _lockupPeriod,uint256 _interest);
  // @dev emitted whenever user stakes tokens in the Stake Account
  event ClaimedStakedTokens(address indexed _user,uint256 _amount);
   // @dev emitted whenever user stakes tokens for One month LockUp period
  event OneMonthStaked(address indexed _user,uint256 _amount,uint256 _lockupPeriod, uint256 _interest);
   // @dev emitted whenever user stakes tokens for Three month LockUp period
  event ThreeMonthStaked(address indexed _user,uint256 _amount,uint256 _lockupPeriod, uint256 _interest);
   // @dev emitted whenever user's staked tokens are successfully unstaked and trasnferred back to the user
  event ClaimedInterestTokens(address indexed _user,uint256 _amount);  
    // @dev emitted whenever weekly token rewards are transferred to the user. 
  event TokenRewardTransferred(address indexed _user,uint256 _amount);
 

  // @dev returns the current tokenBalance of the Stake Contract
  function totalStakedTokens() external view returns(uint256){
      return ERC20(swanTokenAddress).balanceOf(address(this));
  }

  function setPrice(uint256 price) external onlyOwner{
    require (price > 0,"Price Cannot be ZERO");
    currentPrice = price;
  }
  
   /**
      * @param _amount - the amount user wants to stake
      * @dev allows the user to stake the initial $2000 worth of SWAN tokens
      *      Lists the user as a valid Staker.(by adding True in the isStaker mapping) 
      *      User can earn comparatively more interest on Future stakes by calling this function
  **/
  function stake(uint256 _amount) external whenNotPaused returns(bool){
    require(!isStaker[msg.sender],"Previous Staked Amount is not Withdrawn yet");  
    require (_amount >= currentPrice.mul(2000),"Staking Amount is Less Than $2000");
    
    require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),_amount),"Token Transfer Failed");
  
      stakeAccountDetails[msg.sender] = StakeAccount(
    {
      stakedAmount:_amount,
      time:now,
      interestRate:14,
      unstaked:false
    });
      isStaker[msg.sender] = true;
      userTotalStakes[msg.sender] += _amount;
      emit staked(msg.sender,_amount,4,14);
      return true;
  }  
  /**
   *  @notice Assigns the interestRates to users investments based on their time Duration and Stake Criteria
   *  @param  amount-  The amount user wishes to Stake
   *  @param  duration-   The lockUp duration
   *  @return true or false based on the function execution
  */

    function earnInterest(uint256 amount,uint256 duration) external whenNotPaused returns(bool){
      require (amount>0,"Amount can not be equal to ZERO");
      require (duration>0,"Duration can not be Zero");

      require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');

       uint256 oneMonthNum = interestAccountNumber[msg.sender].add(1);
      if(isStaker[msg.sender]){

         if(duration == 3){
         interestAccountDetails[msg.sender][oneMonthNum] = InterestAccount(
           {
                amount: amount,
                time: now,
                interestRate : 20,
                interestPayouts : 0,
                timeperiod : duration,
                withdrawn : false

           }); 
         emit ThreeMonthStaked(msg.sender,amount,duration,20);
        }else if(duration == 1){
          interestAccountDetails[msg.sender][oneMonthNum] = InterestAccount(
           {
                amount: amount,
                time: now,
                interestRate : 16,
                interestPayouts : 0,
                timeperiod : duration,
                withdrawn : false

           });
           emit OneMonthStaked(msg.sender,amount,duration,16); 
        }
      }else{
        if(duration == 3){
         interestAccountDetails[msg.sender][oneMonthNum] = InterestAccount(
           {
                amount: amount,
                time: now,
                interestRate : 16,
                interestPayouts : 0,
                timeperiod : duration,
                withdrawn : false

           }); 
         emit ThreeMonthStaked(msg.sender,amount,duration,16);
        }else if(duration == 1){
          interestAccountDetails[msg.sender][oneMonthNum] = InterestAccount(
           {
                amount: amount,
                time: now,
                interestRate : 12,
                interestPayouts : 0,
                timeperiod : duration,
                withdrawn : false

           }); 
          emit OneMonthStaked(msg.sender,amount,duration,12);
      }   
    }
    userTotalStakes[msg.sender] += amount;
    interestAccountNumber[msg.sender] = interestAccountNumber[msg.sender].add(1);
    return true;
}
    /**
     *  @param id - the interestAccount id 
     *  @dev  allows users to claim their invested tokens for 1 or 3 months from same function
     *        calculates the remaining interest to be transferred to the user
     *        transfers the invested amount as well as the remaining interest to the user.
     *        updates the user's staked balance to ZERO
     */
    function claimInterestTokens(uint256 id) external whenNotPaused{
        InterestAccount memory interestData =  interestAccountDetails[msg.sender][id];
        require (now >= interestData.time.add(interestData.timeperiod.mul(2629746)),"Deadline is not over"); // 2,629,746 seconds = 1 month
        require (interestData.amount > 0,"Invested Amount is ZERO");
      
        uint256 interestAmount = interestData.amount.mul(interestData.interestRate).div(100);
        uint256 remainingInterest = interestAmount.sub(totalPoolRewards[msg.sender][id]);
        uint256 tokensToSend = interestData.amount.add(remainingInterest);
        
        require(ERC20(swanTokenAddress).transfer(msg.sender, tokensToSend),"Token Transfer Failed");
        userTotalStakes[msg.sender] -= interestData.amount;
        interestData.withdrawn = true;
        interestData.amount = 0;
        interestAccountDetails[msg.sender][id] = interestData;
        emit ClaimedInterestTokens(msg.sender,tokensToSend);
    } 
   /**
     *  @dev  allows users to claim their staked tokens for 4 months
     *        calculates the total interest to be transferred to the user after 4 months
     *        transfers the staked amount as well as the remaining interest to the user.
     *        marks the user as NON STAKER.
     * 
     */
  function claimStakeTokens() external whenNotPaused{
      require(isStaker[msg.sender],"User is not a Staker");

      StakeAccount memory stakeData = stakeAccountDetails[msg.sender];
      require (now >= stakeData.time.add(10518984),"LockUp Period NOT OVER Yet"); // 10,518,984 seconds = 4 months 
      uint256 interestAmount = stakeData.stakedAmount.mul(14).div(100);
      uint256 tokensToSend = stakeData.stakedAmount.add(interestAmount);
      require(ERC20(swanTokenAddress).transfer(msg.sender, tokensToSend),"Token Transfer Failed");
      
      userTotalStakes[msg.sender] -= stakeData.stakedAmount;
      isStaker[msg.sender] = false;
      stakeData.unstaked = true;
      stakeAccountDetails[msg.sender] = stakeData;
      emit ClaimedStakedTokens(msg.sender,tokensToSend);
    } 
  /**
     *  @param id - the interestAccount id 
     *  @dev  allows users to claim their weekly interests
     *        updates the totalRewards earned by the user on a particular investment
     *        Total interest is divided into the number of weeks during the lockUpPeriod
     *        The remaining weekly interests(if any) will be withdrawn at the time of claiming the particular interestAccount.
     * 
     */
     function payOuts (uint256 id) external returns(bool) {  
        InterestAccount memory interestData =  interestAccountDetails[msg.sender][id];
        require (now <= interestData.time.add(interestData.timeperiod.mul(2629746)),"Reward Timeline is Over");// 2,629,746 seconds = 1 month
        require(!interestData.withdrawn,"Amount Has already Been Withdrawn");

        uint256 preSaleCycle = getCycle(msg.sender, id);
        require (preSaleCycle > 0,"Cycle is not complete");

        uint256 interestAmount = interestData.amount.mul(interestData.interestRate).div(100);
        uint256 onePercentOfInitialFund = interestAmount.div(interestData.timeperiod.mul(4));
        
        if(interestData.interestPayouts <= onePercentOfInitialFund.mul(preSaleCycle)) {   
          uint256 tokenToSend = onePercentOfInitialFund.mul(preSaleCycle).sub(interestData.interestPayouts);
          require(tokenToSend.add(totalPoolRewards[msg.sender][id]) <= interestAmount,"Total Interest has already been given out");
          interestData.interestPayouts = onePercentOfInitialFund.mul(preSaleCycle);
          require(ERC20(swanTokenAddress).transfer(msg.sender, tokenToSend),"Token Transfer Failed");
          totalPoolRewards[msg.sender][id] += tokenToSend;
          emit TokenRewardTransferred(msg.sender,tokenToSend);
          return true;
        }
    }
   /**
     *  @notice returns the cycle for weekly payouts
     *  @param userAddress,id - takes caller's address and interstAccount 
     *  @dev  calculates the number of week cycles passed 
     */
    function getCycle(address userAddress, uint256 id) internal returns (uint256){
     
      InterestAccount memory interestData =  interestAccountDetails[userAddress][id];
      require (interestData.amount > 0,"Amount Withdrawn Already");
      uint256 cycle;
      if(checkCycle[userAddress][id]){
          cycle = now.sub(lastPayoutCall[userAddress][id]);
      }else{
          cycle = now.sub(interestData.time);
          checkCycle[userAddress][id] = true;
      }
       if(cycle <= 21600)//21600 6 hours for testing 
       {
           return 0;
       }
       else if (cycle > 21600)//21600 6 hours 
       {     
        require(now.sub(lastPayoutCall[userAddress][id]) >= 21600,"Cannot Call Before 6 hours");
        uint256 secondsToHours = cycle.div(21600);//21600 6 hours
        lastPayoutCall[userAddress][id] = now;
        return secondsToHours;
       }
     }

    function getUserStakedAmount(address userAddress) external view returns (uint256) {
      return userTotalStakes[userAddress];
  }


}


