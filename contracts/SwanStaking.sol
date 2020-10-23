/**
 *Submitted for verification at Etherscan.io on 2020-10-09
*/

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


contract SwanStaking is Pausable{

    using SafeMath for uint256;


    address public swanTokenAddress;
    /**
     * @dev address of a token contrac swan 
     */
    constructor(address swanToken) public Owned(msg.sender) {

    swanTokenAddress = swanToken;
}
    struct staking 
    {

    uint256 amount;
    uint256 time;
    uint256 interestRate;
    uint256 interestPayouts;
    uint256 timeperiod;


    }


  mapping(address => uint256) public userTotalStakes;
  mapping(address => uint256) public totalPoolRewards;
  mapping (address => uint256) public oneMonthNumber;
  mapping(address => mapping (uint256 => staking)) public stakingDetails;


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
  event claimedTokensTransferred(address indexed _user,uint256 _amount);
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
     * @dev  stake for one month only

     */

  function stakeTokensOneMonth (uint256 amount)  external returns (bool) {
      
      if (amount >= 2000 ether) {
          
       require(ERC20(swanTokenAddress).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       uint256 checkAllowance = ERC20(swanTokenAddress).allowance(msg.sender, address(this)); 
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');
       
       uint256 oneMonthNum = oneMonthNumber[msg.sender];
       
     stakingDetails[msg.sender][oneMonthNum ++] = staking(
       {

            amount: amount,
            time: now,
            interestRate : 16,
            interestPayouts : 0,
            timeperiod : 1

       });       

        userTotalStakes[msg.sender] += amount;
        oneMonthNumber[msg.sender]++;
        emit oneMonthStaked(msg.sender,amount,1,16);
      } else {
          
       require(ERC20(swanTokenAddress).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       uint256 checkAllowance = ERC20(swanTokenAddress).allowance(msg.sender, address(this)); 
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');          

       uint256 oneMonthNum = oneMonthNumber[msg.sender];
       
     stakingDetails[msg.sender][oneMonthNum ++] = staking(
       {

            amount: amount,
            time: now,
            interestRate : 12,
            interestPayouts : 0,
            timeperiod : 1

       });       
          userTotalStakes[msg.sender] += amount;
          oneMonthNumber[msg.sender]++;
          emit oneMonthStaked(msg.sender,amount,1,12);

      }
  }  

    /**
     * @dev  stake for three month only

     */
  function stakeTokensThreeMonth (uint256 amount)  external returns (bool) {
      
      if (amount >= 2000 ether) {
          
       require(ERC20(swanTokenAddress).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       uint256 checkAllowance = ERC20(swanTokenAddress).allowance(msg.sender, address(this)); 
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');
              uint256 oneMonthNum = oneMonthNumber[msg.sender];
       
        stakingDetails[msg.sender][oneMonthNum ++] = staking(
       {

            amount: amount,
            time: now,
            interestRate : 20,
            interestPayouts : 0,
            timeperiod : 3

       });       
        userTotalStakes[msg.sender] += amount;
        oneMonthNumber[msg.sender]++;
        emit threeMonthStaked(msg.sender,amount,3,20);
          
      } else {
          
       require(ERC20(swanTokenAddress).balanceOf(msg.sender) >= amount,'balance of a user is less then value');
       uint256 checkAllowance = ERC20(swanTokenAddress).allowance(msg.sender, address(this)); 
       require (checkAllowance >= amount, 'allowance is wrong');
       require(ERC20(swanTokenAddress).transferFrom(msg.sender,address(this),amount),'transfer From failed');          

              uint256 oneMonthNum = oneMonthNumber[msg.sender];
       
        stakingDetails[msg.sender][oneMonthNum ++] = staking(
       {

            amount: amount,
            time: now,
            interestRate : 16,
            interestPayouts : 0,
            timeperiod : 3

       });       
          userTotalStakes[msg.sender] += amount;
          oneMonthNumber[msg.sender]++;
          emit threeMonthStaked(msg.sender,amount,3,16);
      }
    }

    /**
     * @dev  claim tokens for 1 or 3 months from same function

     */
    function claimTokens(uint256 id) public returns (bool) {
       
        staking memory OneMonth =  stakingDetails[msg.sender][id];
        require (OneMonth.amount >= 0 );
        require (OneMonth.time >= now.add(86400));//change it to one month for production use 
        require(ERC20(swanTokenAddress).transfer(msg.sender, OneMonth.amount));
        userTotalStakes[msg.sender] -= OneMonth.amount;
        emit claimedTokensTransferred(msg.sender,OneMonth.amount);
        OneMonth.amount = 0;

        
    } 

    /**
     * @dev  user can claim payouts in everyt seven days 

     */

    function payOuts (uint256 id) public returns (bool) {
        
        staking memory OneMonth =  stakingDetails[msg.sender][id];
        require (OneMonth.amount >= 0 );
        require (OneMonth.time >= now.add(86400));//change it to one month for production use 

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
     
        staking memory OneMonth =  stakingDetails[userAddress][id];
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
