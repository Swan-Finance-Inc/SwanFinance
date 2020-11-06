pragma solidity 0.5.16;

contract ERC20 {

    function transferFrom (address,address, uint256) external returns (bool);
    function balanceOf(address) public view returns (uint256);
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

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
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

    function pause() onlyOwner whenNotPaused public {
      paused = true;
      emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
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
    struct interestAccount 
    {

    uint256 amount;
    uint256 time;
    uint256 interestRate;
    uint256 interestPayouts;
    uint256 timeperiod;
    }

  // isStaker is TRUE for those addresses which have staked $2000 worth tokens.
  mapping(address => bool) public isStaker;
  mapping(address => uint256) public userTotalStakes;
  mapping(address => uint256) public totalPoolRewards;

  mapping (address => uint256) public interestAccountNumber;
  mapping(address => StakeAccount) public stakeAccountDetails;
  mapping(address => mapping (uint256 => interestAccount)) public interestAccountDetails;


  /**
     * @dev emitted whenever user stakes tokens in the Stake Account
  */
   
  event staked(address indexed _user,uint256 _amount,uint256 _lockupPeriod,uint256 _interest);
   
  /**
     * @dev emitted whenever user stakes tokens in the Stake Account
  **/

  event claimedStakedTokens(address indexed _user,uint256 _amount);
  
    /**
     * @dev emitted whenever user stakes tokens for One month LockUp period
     */
  event oneMonthStaked(address indexed _user,uint256 _amount,uint256 _lockupPeriod, uint256 _interest);
   /**
     * @dev emitted whenever user stakes tokens for Three month LockUp period
    */
  event threeMonthStaked(address indexed _user,uint256 _amount,uint256 _lockupPeriod, uint256 _interest);
   /**
     * @dev emitted whenever user's staked tokens are successfully unstaked and trasnferred back to the user
    */
  event claimedInterestTokens(address indexed _user,uint256 _amount);
   /**
     * @dev emitted whenever weekly token rewards are transferred to the user.
    */
  event tokenRewardTransferred(address indexed _user,uint256 _amount);


  /**
      * @dev returns the total amount of SWAN tokens staked in this contract
  **/

  function totalStakedTokens() public view returns(uint256){
      return ERC20(swanTokenAddress).balanceOf(address(this));
  }
   
   /**
      * @param _amount - the amount user wishes to stake
      * @dev allows the user to stake the initial $2000 worth of SWAN tokens
      *      Lists the user as a valid Staker.(by adding True in the isStaker mapping) 
      *      User can earn comparatively more interest on Future stakes.
  **/

  
  function stake(uint256 _amount) external returns(bool){
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
  }    
      /**
     * @dev  User can earn interest by staking for 1 month

     */


  function stakeTokensOneMonth (uint256 amount)  external returns (bool) {   
       require(ERC20(swanTokenAddress).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       uint256 checkAllowance = ERC20(swanTokenAddress).allowance(msg.sender, address(this)); 
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');
       
       uint256 oneMonthNum = interestAccountNumber[msg.sender];
      if (isStaker[msg.sender]){
       interestAccountDetails[msg.sender][oneMonthNum ++] = interestAccount(
         {
              amount: amount,
              time: now,
              interestRate : 16,
              interestPayouts : 0,
              timeperiod : 1

         });       

        emit oneMonthStaked(msg.sender,amount,1,16);
      }else {
         interestAccountDetails[msg.sender][oneMonthNum ++] = interestAccount(
           {
                amount: amount,
                time: now,
                interestRate : 12,
                interestPayouts : 0,
                timeperiod : 1
           });  
           emit oneMonthStaked(msg.sender,amount,1,12);     
          }

      userTotalStakes[msg.sender] += amount;
      interestAccountNumber[msg.sender]++; 
  }  
    /**
     * @dev  User can earn interest by staking for 3 month

     */
  function stakeTokensThreeMonth (uint256 amount)  external returns (bool) {
        
     require(ERC20(swanTokenAddress).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
     uint256 checkAllowance = ERC20(swanTokenAddress).allowance(msg.sender, address(this)); 
     require (checkAllowance >= amount, 'allowance is wrong');
     require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');
    
     uint256 oneMonthNum = interestAccountNumber[msg.sender];
    if (isStaker[msg.sender]){
       interestAccountDetails[msg.sender][oneMonthNum ++] = interestAccount(
         {
              amount: amount,
              time: now,
              interestRate : 20,
              interestPayouts : 0,
              timeperiod : 3
         });       

        emit oneMonthStaked(msg.sender,amount,3,20);
      }else {
         interestAccountDetails[msg.sender][oneMonthNum ++] = interestAccount(
           {
              amount: amount,
              time: now,
              interestRate : 16,
              interestPayouts : 0,
              timeperiod : 3
           });  
           emit oneMonthStaked(msg.sender,amount,3,16);     
          }
      userTotalStakes[msg.sender] += amount;
      interestAccountNumber[msg.sender]++; 
  }  

    /**
     * @dev  claim tokens for 1 or 3 months from same function

     */
    function claimInterestTokens(uint256 id) public returns (bool) {
       
        interestAccount memory OneMonth =  interestAccountDetails[msg.sender][id];
        require (OneMonth.amount >= 0 );
        require (now >= OneMonth.time.add(OneMonth.timeperiod * 1 minutes),"Deadline is not over");// will be chnanged to "months" time unit for production

        uint256 totalInterest = OneMonth.interestRate.mul(OneMonth.timeperiod);
        uint256 interestAmount = OneMonth.amount.mul(totalInterest).div(100);
        uint256 tokensToSend = OneMonth.amount.add(interestAmount);

        require(ERC20(swanTokenAddress).transfer(msg.sender, tokensToSend));
        userTotalStakes[msg.sender] -= OneMonth.amount;
         totalPoolRewards[msg.sender] += interestAmount;
        emit claimedInterestTokens(msg.sender,tokensToSend);
        OneMonth.amount = 0;
    } 
    

  function claimStakeTokens() public{
      require(isStaker[msg.sender],"User is not a Staker");

      StakeAccount memory stakeData = stakeAccountDetails[msg.sender];
      //require (now >= stakeData.time.add(10368000),"Deadline NOT OVER"); //will be changed to 4 months for production use 
      uint256 interestAmount = stakeData.stakedAmount.mul(64).div(100);
      uint256 tokensToSend = stakeData.stakedAmount.add(interestAmount);
      require(ERC20(swanTokenAddress).transfer(msg.sender, tokensToSend));
      
      userTotalStakes[msg.sender] -= stakeData.stakedAmount;
      isStaker[msg.sender] = false;
      stakeData.unstaked = true;
      stakeAccountDetails[msg.sender] = stakeData;
      totalPoolRewards[msg.sender] += interestAmount;
     
      emit claimedStakedTokens(msg.sender,tokensToSend);
    } 
    /**
     * @dev  user can claim payouts in everyt seven days 

     */

    function payOuts (uint256 id) public returns (bool) {
        
        interestAccount memory OneMonth =  interestAccountDetails[msg.sender][id];
        require (OneMonth.amount >= 0 );
        require (now >= OneMonth.time.add(100));//change it to one month for production use 

        uint256 preSaleCycle = getCycle(msg.sender, id);
        require (preSaleCycle > 0);

        uint256 onePercentOfInitialFund = OneMonth.amount.div(86400);
        if(OneMonth.interestPayouts <= onePercentOfInitialFund.mul(preSaleCycle)) {
            
        uint256 tokenToSend = onePercentOfInitialFund.mul(preSaleCycle).sub(OneMonth.interestPayouts);
        OneMonth.interestPayouts = onePercentOfInitialFund.mul(preSaleCycle);
        require(ERC20(swanTokenAddress).transfer(msg.sender, tokenToSend));
        totalPoolRewards[msg.sender] += tokenToSend;
        emit tokenRewardTransferred(msg.sender,tokenToSend);

        }
        
        
    }
        /**
     * @dev  get cycle for payout 

     */
    function getCycle(address userAddress, uint256 id) internal view returns (uint256){
     
        interestAccount memory OneMonth =  interestAccountDetails[userAddress][id];
        require (OneMonth.amount >= 0 );

      uint256 cycle = now.sub(OneMonth.timeperiod);
    
     if(cycle <= 21600)//21600 6 hours for testing 
     {
         return 0;
     }
     else if (cycle > 21600)//21600 6 hours 
     {     
    
      uint256 secondsToHours = cycle.div(21600);//21600 6 hours
      return secondsToHours;
     
     }

    }    

}
