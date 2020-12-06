pragma solidity 0.5.16;

contract SwanToken {

    function transfer (address, uint) public;
    function burnTokensForSale() external returns (bool);
    function saleTransfer(address,uint256,bool) external returns (bool);
    function finalize() external returns (bool);
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

contract Crowdsale is Pausable { 
  
  using SafeMath for uint256;
  uint256 public ethPrice; // 1 Ether price in USD cents.

  SwanToken public token;

  uint256 public hardCap = 0; 
  uint256 public softCap = 500000000; // in cents 

  //total tokens for sale 
  uint256 public tokensForSale = 140000000000 ether;

  // tokens sold in each round of sale 
  uint256 public privateSaletokenSold = 0;
  uint256 public preSaleTokensSold = 0;
  uint256 public crowdSaleRoundOne = 0;
  uint256 public crowdSaleRoundTwo = 0;
  uint256 public crowdSaleRoundThree = 0;
  uint256 public crowdSaleRoundFour = 0;

  // tokenSoldLimit in rounds
  uint256 public privateSaletokenLimit = 2500000000;
  uint256 public preSaleTokensLimit = 2400000000;
  uint256 public crowdSaleRoundOneLimit = 2300000000;
  uint256 public crowdSaleRoundTwoLimit = 2200000000;
  uint256 public crowdSaleRoundThreeLimit = 2100000000;
  uint256 public crowdSaleRoundFourLimit = 2500000000;

  
  // Address where funds are collected
  address  payable public  wallet;

  uint256 public bonusPercentPrivateSale  = 25;
  uint256 public bonusPercentPreSale = 20;
  uint256 public bonusPercentRoudOne = 15;
  uint256 public bonusPercentRoudTwo = 10;
  uint256 public bonusPercentRoudThree = 5;
  uint256 public bonusPercentRoudFour = 0;  

// user limit

  uint256 public minimumInvestment = 50000;
  uint256 public maximumInvestment = 20000000;
  uint256 public tokensInOneDollar = 1000;

  bool public crowdSaleStarted = false;

  enum Stages {CrowdSaleNotStarted, Pause, PrivateSaleStart,PrivateSaleEnd, PreSaleStart, PreSaleEnd, CrowdSaleRoundOneStart,CrowdSaleRoundOneEnd, CrowdSaleRoundTwoStart, CrowdSaleRoundTwoEnd, CrowdSaleRoundThreeStart, CrowdSaleRoundThreeEnd, CrowdSaleRoundFourStart, CrowdSaleRoundFourEnd}

  Stages currentStage;
  Stages previousStage;
  bool public Paused;

   // adreess vs state mapping (1 for exists , zero default);
   mapping (address => bool) public whitelistedContributors;

  
   modifier CrowdsaleStarted(){

      require(crowdSaleStarted);
      _;
   }
 
    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    *@dev initializes the crowdsale contract 
    * @param _newOwner Address who has special power to change the ether price in cents according to the market price
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    *  @param _ethPriceInCents ether price in cents
    */
    constructor(address _newOwner, address payable _wallet, SwanToken _token,uint256 _ethPriceInCents) Owned(_newOwner) public {

        wallet = _wallet;
        owner = _newOwner;
        token = _token;
        ethPrice = _ethPriceInCents; //ethPrice in cents
        currentStage = Stages.CrowdSaleNotStarted;

    }
    
    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
    
     if(msg.sender != owner){

        buyTokens(msg.sender); 

     }
     else{
     revert();
     }
     
    }

    /**
    * @dev whitelist addresses of investors.
    * @param addrs ,array of addresses of investors to be whitelisted
    * Note:= Array length must be less than 200.
    */
    function authorizeKyc(address[] memory addrs) public onlyOwner returns (bool success) {
        uint arrayLength = addrs.length;
        for (uint x = 0; x < arrayLength; x++) 
        {
            whitelistedContributors[addrs[x]] = true;
        }
        return true;
    }
    
    /**
    * @dev calling this function will pause the sale
    */
    
    function pause() public onlyOwner {
      require(Paused == false);
      require(crowdSaleStarted == true);
      previousStage=currentStage;
      currentStage=Stages.Pause;
      Paused = true;
    }
  
    function restartSale() public onlyOwner {
      require(currentStage == Stages.Pause);
      currentStage=previousStage;
      Paused = false;
    }

    function startPrivateSale() public onlyOwner {
      require(!crowdSaleStarted);
      crowdSaleStarted = true;
      currentStage = Stages.PrivateSaleStart;
    }

    function endPrivateSale() public onlyOwner {

      require(currentStage == Stages.PrivateSaleStart);
      currentStage = Stages.PrivateSaleEnd;

    }

    function startPreSale() public onlyOwner {

    require(currentStage == Stages.PrivateSaleEnd);
    currentStage = Stages.PreSaleStart;
   
    }

    function endPreSale() public onlyOwner {

    require(currentStage == Stages.PreSaleStart);
    currentStage = Stages.PreSaleEnd;
   
    }

    function startCrowdSaleRoundOne() public onlyOwner {

    require(currentStage == Stages.PreSaleEnd);
    currentStage = Stages.CrowdSaleRoundOneStart;

    }

    function endCrowdSaleRoundOne() public onlyOwner {

    require(currentStage == Stages.CrowdSaleRoundOneStart);
    currentStage = Stages.CrowdSaleRoundOneEnd;

    }

    function startCrowdSaleRoundTwo() public onlyOwner {

    require(currentStage == Stages.CrowdSaleRoundOneEnd);
    currentStage = Stages.CrowdSaleRoundTwoStart;

    }

    function endCrowdSaleRoundTwo() public onlyOwner {

    require(currentStage == Stages.CrowdSaleRoundTwoStart);
    currentStage = Stages.CrowdSaleRoundTwoEnd;

    }

    function startCrowdSaleRoundThree() public onlyOwner {

    require(currentStage == Stages.CrowdSaleRoundTwoEnd);
    currentStage = Stages.CrowdSaleRoundThreeStart;

    }

    function endCrowdSaleRoundThree() public onlyOwner {

    require(currentStage == Stages.CrowdSaleRoundThreeStart);
    currentStage = Stages.CrowdSaleRoundThreeEnd;

    }

    function startCrowdSaleRoundFour() public onlyOwner {

    require(currentStage == Stages.CrowdSaleRoundThreeEnd);
    currentStage = Stages.CrowdSaleRoundFourStart;

    }

    function endCrowdSaleRoundFour() public onlyOwner {

    require(currentStage == Stages.CrowdSaleRoundFourStart);
    currentStage = Stages.CrowdSaleRoundFourEnd;

    }

    function getStage() public view returns (string memory) {
    if (currentStage == Stages.PrivateSaleStart) return 'Private Sale Start';
    else if (currentStage == Stages.PrivateSaleEnd) return 'Private Sale End';
    else if (currentStage == Stages.PreSaleStart) return 'Presale Started';
    else if (currentStage == Stages.PreSaleEnd) return 'Presale Ended';
    else if (currentStage == Stages.CrowdSaleRoundOneStart) return 'CrowdSale Round One Started';
    else if (currentStage == Stages.CrowdSaleRoundOneEnd) return 'CrowdSale Round One End';
    else if (currentStage == Stages.CrowdSaleRoundTwoStart) return 'CrowdSale Round Two Started';
    else if (currentStage == Stages.CrowdSaleRoundTwoEnd) return 'CrowdSale Round Two End';
    else if (currentStage == Stages.CrowdSaleRoundThreeStart) return 'CrowdSale Round Three Started';
    else if (currentStage == Stages.CrowdSaleRoundThreeEnd) return 'CrowdSale Round Three End';
    else if (currentStage == Stages.CrowdSaleRoundFourStart) return 'CrowdSale Round Four Started';    
    else if (currentStage == Stages.CrowdSaleRoundFourEnd) return 'CrowdSale Round Four End';   
    else if (currentStage == Stages.Pause) return 'paused';
    else if (currentStage == Stages.CrowdSaleNotStarted) return 'CrowdSale Not Started';    
    }
    
   /**
   * @dev sets the value of ether price in cents.Can be called only by the owner account.
   * @param _ethPriceInCents price in cents .
   */
   function setEthPriceInCents(uint _ethPriceInCents) onlyOwner public returns(bool) {
        ethPrice = _ethPriceInCents;
        return true;
    }

   /**
   * @param _beneficiary Address performing the token purchase
   */
   function buyTokens(address _beneficiary) CrowdsaleStarted public payable {

    require(whitelistedContributors[_beneficiary] == true, "Not a whitelistedInvestor");
    require(Paused != true, "Contract is Paused");
    uint256 weiAmount = msg.value;
    uint256 usdCents = weiAmount.mul(ethPrice).div(1 ether); 

    _preValidatePurchase(usdCents);

    uint256 tokens = _getTokenAmount(usdCents);

    _validateTokenCapLimits(usdCents);

    _processPurchase(_beneficiary,tokens);

    wallet.transfer(msg.value);

    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
   }
  
   /**
   * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
   * @param _usdCents Value in usdincents involved in the purchase
   */
   function _preValidatePurchase(uint256 _usdCents) internal view { 

       require(_usdCents >= minimumInvestment && _usdCents <= maximumInvestment);

    }
    
    /**
    * @dev Validation of the capped restrictions.
    * @param _tokenValue amount
    */

    function _validateTokenCapLimits(uint256 _tokenValue) internal {
     
    if (currentStage == Stages.PrivateSaleStart) {
        
        require(privateSaletokenSold.add(_tokenValue) <= privateSaletokenLimit);
        privateSaletokenSold = privateSaletokenSold.add(_tokenValue);
        
    }

    else if (currentStage == Stages.PreSaleStart) {
        
        require(preSaleTokensSold.add(_tokenValue) <= preSaleTokensLimit);
        preSaleTokensSold = preSaleTokensSold.add(_tokenValue);
        
    }

    else if (currentStage == Stages.CrowdSaleRoundOneStart) {
        
        require(crowdSaleRoundOne.add(_tokenValue) <= crowdSaleRoundOneLimit);
        crowdSaleRoundOne = crowdSaleRoundOne.add(_tokenValue);        
        
    }

    else if (currentStage == Stages.CrowdSaleRoundTwoStart) {
        
        require(crowdSaleRoundTwo.add(_tokenValue) <= crowdSaleRoundTwoLimit);
        crowdSaleRoundTwo = crowdSaleRoundTwo.add(_tokenValue);        
        
    }

    else if (currentStage == Stages.CrowdSaleRoundThreeStart) {
        
        require(crowdSaleRoundThree.add(_tokenValue) <= crowdSaleRoundThreeLimit);
        crowdSaleRoundThree = crowdSaleRoundThree.add(_tokenValue);        
        
    }

    else if (currentStage == Stages.CrowdSaleRoundFourStart) {
        
        require(crowdSaleRoundFour.add(_tokenValue) <= crowdSaleRoundFourLimit);
        crowdSaleRoundFour = crowdSaleRoundFour.add(_tokenValue);        

    }    

    else { revert("No active Sale");}

   }
   
   /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
   function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    

       require(token.saleTransfer(_beneficiary, _tokenAmount, false));    

   }

   /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
   function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
   }
  

    /**
    * @param _usdCents Value in usd cents to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _usdCents
    */
    function _getTokenAmount(uint256 _usdCents) CrowdsaleStarted internal view returns (uint256) {

         uint256 bonusUSD;
         uint256 bonusTokens;
         uint256 actualTokens;
         uint256 totalTokens;

     
      if (currentStage == Stages.PrivateSaleStart) {
         

         bonusUSD = (_usdCents.div(100)).mul(25).div(100);
         bonusTokens = bonusUSD.mul(tokensInOneDollar);
         actualTokens = _usdCents.div(100).mul(tokensInOneDollar);
         totalTokens = bonusTokens.add(actualTokens);


      }
      else if (currentStage == Stages.PreSaleStart) {

         bonusUSD = (_usdCents.div(100)).mul(25).div(100);
         bonusTokens = bonusUSD.mul(tokensInOneDollar);
         actualTokens = _usdCents.div(100).mul(tokensInOneDollar);
         totalTokens = bonusTokens.add(actualTokens); 
         
      }
      else if (currentStage == Stages.CrowdSaleRoundOneStart) {

         bonusUSD = (_usdCents.div(100)).mul(25).div(100);
         bonusTokens = bonusUSD.mul(tokensInOneDollar);
         actualTokens = _usdCents.div(100).mul(tokensInOneDollar);
         totalTokens = bonusTokens.add(actualTokens);
         
      }
      else if (currentStage == Stages.CrowdSaleRoundTwoStart) {

         bonusUSD = (_usdCents.div(100)).mul(25).div(100);
         bonusTokens = bonusUSD.mul(tokensInOneDollar);
         actualTokens = _usdCents.div(100).mul(tokensInOneDollar);
         totalTokens = bonusTokens.add(actualTokens);
      }
      else if (currentStage == Stages.CrowdSaleRoundThreeStart) {

         bonusUSD = (_usdCents.div(100)).mul(25).div(100);
         bonusTokens = bonusUSD.mul(tokensInOneDollar);
         actualTokens = _usdCents.div(100).mul(tokensInOneDollar);
         totalTokens = bonusTokens.add(actualTokens);         

      }
      else if (currentStage == Stages.CrowdSaleRoundFourStart) {

         bonusUSD = (_usdCents.div(100)).mul(25).div(100);
         bonusTokens = bonusUSD.mul(tokensInOneDollar);
         actualTokens = _usdCents.div(100).mul(tokensInOneDollar);
         totalTokens = bonusTokens.add(actualTokens);         

      }
    
      return totalTokens;
    }
    
    /**
    * @dev finalize the crowdsale.After finalizing ,tokens transfer can be done.
    */
    function finalizeSale() public  onlyOwner {
        require(currentStage == Stages.CrowdSaleRoundFourEnd);
        require(token.finalize());
        
    }


}
