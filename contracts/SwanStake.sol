pragma solidity 0.5.16;

contract ERC20 {

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
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid Address: New owner is the zero address");
        newOwner = _newOwner;
    }
    function acceptOwnership() external {
        require(msg.sender == newOwner);
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
      require(!paused);
      _;
    }

    modifier whenPaused() {
      require(paused);
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

    /**
     * @dev address of a token contrac swan 
     */
    constructor(address swanToken) public Owned(msg.sender) {

    swanTokenAddress = swanToken;
  }

  // Includes all the necessary details about the User's initial $2000 stake.
    struct StakeAccount{
      uint256 stakedAmount;
      uint256 time;
      uint256 interestRate;
      bool unstaked;
    }
// Includes details about further major or minor stakes by a user in order to earn interest
    struct InterestAccount 
    {

    uint256 amount;
    uint256 time;
    uint256 interestRate;
    uint256 interestPayouts;
    uint256 timeperiod;
    bool withdrawn;
    }

  // isStaker is TRUE for those addresses which have staked $2000 worth tokens.
  mapping(address => bool) public isStaker;
  mapping(address => uint256) public userTotalStakes;
  mapping (address => uint256) public InterestAccountNumber;
  mapping(address => StakeAccount) public stakeAccountDetails;
  mapping(address=>mapping(uint256 => uint256)) public lastPayoutCall;
  mapping(address => mapping(uint256 => uint256)) public totalPoolRewards;
  mapping(address => mapping(uint256 => bool)) public checkCycle;
  mapping(address => mapping (uint256 => InterestAccount)) public InterestAccountDetails;


  //  @dev emitted whenever user stakes tokens in the Stake Account
  event staked(address indexed _user,uint256 _amount,uint256 _lockupPeriod,uint256 _interest);
  // @dev emitted whenever user stakes tokens in the Stake Account
  event claimedStakedTokens(address indexed _user,uint256 _amount);
  
   // @dev emitted whenever user stakes tokens for One month LockUp period
  event oneMonthStaked(address indexed _user,uint256 _amount,uint256 _lockupPeriod, uint256 _interest);
   // @dev emitted whenever user stakes tokens for Three month LockUp period
    
  event threeMonthStaked(address indexed _user,uint256 _amount,uint256 _lockupPeriod, uint256 _interest);
   // @dev emitted whenever user's staked tokens are successfully unstaked and trasnferred back to the user
  event claimedInterestTokens(address indexed _user,uint256 _amount);
  
    // @dev emitted whenever weekly token rewards are transferred to the user.
   
  event tokenRewardTransferred(address indexed _user,uint256 _amount);
    // @dev returns the total amount of SWAN tokens staked in this contract
 

  // @dev returns the current tokenBalance of the Stake Contract
  function totalStakedTokens() external view returns(uint256){
      return ERC20(swanTokenAddress).balanceOf(address(this));
  }
   
   /**
      * @param _amount - the amount user wants to stake
      * @dev allows the user to stake the initial $2000 worth of SWAN tokens
      *      Lists the user as a valid Staker.(by adding True in the isStaker mapping) 
      *      User can earn comparatively more interest on Future stakes by calling this function
  **/

  
  function stake(uint256 _amount) external whenNotPaused returns(bool){
    require(!isStaker[msg.sender],"Previous Staked Amount is not Withdrawn yet");  
    require (_amount >= 2000 ether,"Staking Amount is Less Than $2000");
    
    require (ERC20(swanTokenAddress).balanceOf(msg.sender) >= _amount, "User doesn't have Enough Balance");
    uint256 checkAllowance = ERC20(swanTokenAddress).allowance(msg.sender, address(this)); 
    require (checkAllowance >= _amount,"User has not approved the contract yet.");
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
     *  @param amount - the amount user wants to invest
     *  @dev  User can earn interest by staking for 1 month
     *        User will get higher APY if he is a Staker
     */
  function stakeTokensOneMonth (uint256 amount)  external whenNotPaused returns (bool) {   
       require (amount>0,"Amount can not be equal to ZERO");
   
       require(ERC20(swanTokenAddress).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       uint256 checkAllowance = ERC20(swanTokenAddress).allowance(msg.sender, address(this)); 
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');
       
       uint256 oneMonthNum = InterestAccountNumber[msg.sender].add(1);
      if (isStaker[msg.sender]){
       InterestAccountDetails[msg.sender][oneMonthNum] = InterestAccount(
         {
              amount: amount,
              time: now,
              interestRate : 16,
              interestPayouts : 0,
              timeperiod : 1,
              withdrawn : false

         });       
        emit oneMonthStaked(msg.sender,amount,1,16);
      }else {
         InterestAccountDetails[msg.sender][oneMonthNum ++] = InterestAccount(
           {
                amount: amount,
                time: now,
                interestRate : 12,
                interestPayouts : 0,
                timeperiod : 1,
                withdrawn : false
           });  
           emit oneMonthStaked(msg.sender,amount,1,12);     
          }
      userTotalStakes[msg.sender] += amount;
      InterestAccountNumber[msg.sender] = InterestAccountNumber[msg.sender].add(1);
      return true;
  }  
   /**
     *  @param amount - the amount user wants to invest
     *  @dev  User can earn interest by staking for 3 month
     *        User will get higher APY if he is a Staker
     */
  function stakeTokensThreeMonth (uint256 amount)  external whenNotPaused returns (bool) {
     require (amount>0,"Amount can not be equal to ZERO");

     require(ERC20(swanTokenAddress).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
     uint256 checkAllowance = ERC20(swanTokenAddress).allowance(msg.sender, address(this)); 
     require (checkAllowance >= amount, 'allowance is wrong');
     require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');
    
    uint256 threeMonthNum = InterestAccountNumber[msg.sender].add(1);
    if (isStaker[msg.sender]){
       InterestAccountDetails[msg.sender][threeMonthNum] = InterestAccount(
         {
              amount: amount,
              time: now,
              interestRate : 20,
              interestPayouts : 0,
              timeperiod : 3,
              withdrawn : false
         });       

        emit threeMonthStaked(msg.sender,amount,3,20);
      }else {
         InterestAccountDetails[msg.sender][threeMonthNum] = InterestAccount(
           {
              amount: amount,
              time: now,
              interestRate : 16,
              interestPayouts : 0,
              timeperiod : 3,
              withdrawn : false
           });  
           emit threeMonthStaked(msg.sender,amount,3,6);     
          }
      userTotalStakes[msg.sender] += amount;
      InterestAccountNumber[msg.sender] = InterestAccountNumber[msg.sender].add(1); 
      return true;
  }  

    /**
     *  @param id - the interestAccount id 
     *  @dev  allows users to claim their invested tokens for 1 or 3 months from same function
     *        calculates the remaining interest to be transferred to the user
     *        transfers the invested amount as well as the remaining interest to the user.
     *         updates the user's staked balance to ZERO
     * 
     */
    function claimInterestTokens(uint256 id) external whenNotPaused{
        InterestAccount memory interestData =  InterestAccountDetails[msg.sender][id];
        require (interestData.amount > 0 );
        require (now >= interestData.time.add(interestData.timeperiod.mul(30 days)),"Deadline is not over"); // will be chnanged to "months" time unit for production
      
        uint256 interestAmount = interestData.amount.mul(interestData.interestRate).div(100);
        uint256 remainingInterest = interestAmount.sub(totalPoolRewards[msg.sender][id]);
        uint256 tokensToSend = interestData.amount.add(remainingInterest);
        
        require(ERC20(swanTokenAddress).transfer(msg.sender, tokensToSend));
        userTotalStakes[msg.sender] -= interestData.amount;
        interestData.withdrawn = true;
        interestData.amount = 0;
        InterestAccountDetails[msg.sender][id] = interestData;
        emit claimedInterestTokens(msg.sender,tokensToSend);
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
      require (now >= stakeData.time.add(86400),"LockUp Period NOT OVER Yet"); // 10368000 will be changed to 4 months for production use 
      uint256 interestAmount = stakeData.stakedAmount.mul(14).div(100);
      uint256 tokensToSend = stakeData.stakedAmount.add(interestAmount);
      require(ERC20(swanTokenAddress).transfer(msg.sender, tokensToSend));
      
      userTotalStakes[msg.sender] -= stakeData.stakedAmount;
      isStaker[msg.sender] = false;
      stakeData.unstaked = true;
      stakeAccountDetails[msg.sender] = stakeData;
      emit claimedStakedTokens(msg.sender,tokensToSend);
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
        
        InterestAccount memory interestData =  InterestAccountDetails[msg.sender][id];
        require(!interestData.withdrawn,"Amount Has already Been Withdrawn");
        require (now <= interestData.time.add(interestData.timeperiod.mul(30 days)),"Reward Timeline is Over");//change it to one month for production use 

        uint256 preSaleCycle = getCycle(msg.sender, id);
        require (preSaleCycle > 0,"Cycle is not complete");

        uint256 interestAmount = interestData.amount.mul(interestData.interestRate).div(100);
        uint256 onePercentOfInitialFund = interestAmount.div(interestData.timeperiod.mul(4));
        
        if(interestData.interestPayouts <= onePercentOfInitialFund.mul(preSaleCycle)) {   
        uint256 tokenToSend = onePercentOfInitialFund.mul(preSaleCycle).sub(interestData.interestPayouts);
        require(tokenToSend.add(totalPoolRewards[msg.sender][id]) <= interestAmount,"Total Interest has already been given out");
        interestData.interestPayouts = onePercentOfInitialFund.mul(preSaleCycle);
        require(ERC20(swanTokenAddress).transfer(msg.sender, tokenToSend));
        totalPoolRewards[msg.sender][id] += tokenToSend;
        emit tokenRewardTransferred(msg.sender,tokenToSend);
        return true;

        }
    }
   /**
     *  @param userAddress,id - takes caller's address and interstAccount 
     *  @dev  gets cycle for weekly payouts 
     */

    function getCycle(address userAddress, uint256 id) internal returns (uint256){
     
    InterestAccount memory interestData =  InterestAccountDetails[userAddress][id];
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
      require(now.sub(lastPayoutCall[userAddress][id]) >= 21600,"Cannot Call Before 60 seconds");
      uint256 secondsToHours = cycle.div(21600);//21600 6 hours
      lastPayoutCall[userAddress][id] = now;
      return secondsToHours;
     }
     }
}