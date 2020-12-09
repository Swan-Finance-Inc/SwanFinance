pragma solidity 0.5.16;


//import "@openzeppelin/contracts/ownership/Ownable.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/lifecycle/Pausable.sol";

interface Swan{
    function transfer (address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
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


contract Crowdsale is Pausable { 

  using SafeMath for uint256;
  uint256 public ethPrice; // 1 Ether price in USD cents.

  Swan public token;

  uint256 public hardCap; 
  uint256 public constant softCap = 500000000; // in cents 

  //total tokens for sale 
  uint256 public totalWeiRaised;
  uint256 public tokensForSale = 140000000000 ether;

  // tokens sold in each round of sale 
  uint256 public privateSaletokenSold;
  uint256 public preSaleTokensSold;
  uint256 public crowdSaleRoundOne;
  uint256 public crowdSaleRoundTwo;
  uint256 public crowdSaleRoundThree;
  uint256 public crowdSaleRoundFour;

  // tokenSoldLimit in rounds
  uint256 public constant privateSaletokenLimit = 2500000000;
  uint256 public constant preSaleTokensLimit = 2400000000;
  uint256 public constant crowdSaleRoundOneLimit = 2300000000;
  uint256 public constant crowdSaleRoundTwoLimit = 2200000000;
  uint256 public constant crowdSaleRoundThreeLimit = 2100000000;
  uint256 public constant crowdSaleRoundFourLimit = 2500000000;
  
  // Address where funds are collected
  address  payable public  wallet;

  uint256 public constant bonusPercentPrivateSale  = 25;
  uint256 public constant bonusPercentPreSale = 20;
  uint256 public constant bonusPercentRoudOne = 15;
  uint256 public constant bonusPercentRoudTwo = 10;
  uint256 public constant bonusPercentRoudThree = 5;
  uint256 public constant bonusPercentRoudFour;  

  // user limit
  uint256 public constant minimumInvestment = 50000;
  uint256 public constant maximumInvestment = 20000000;
  uint256 public constant tokensInOneDollar = 1000;

  bool public crowdSaleStarted;

  enum Stages {CrowdSaleNotStarted, Pause, PrivateSaleStart,PrivateSaleEnd, PreSaleStart, PreSaleEnd, CrowdSaleRoundOneStart,CrowdSaleRoundOneEnd, CrowdSaleRoundTwoStart, CrowdSaleRoundTwoEnd, CrowdSaleRoundThreeStart, CrowdSaleRoundThreeEnd, CrowdSaleRoundFourStart, CrowdSaleRoundFourEnd}

  Stages currentStage;
  Stages previousStage;
  bool public Paused;

   // adreess vs state mapping (1 for exists , zero default);
   mapping (address => bool) public whitelistedContributors;

  
   modifier CrowdsaleStarted(){

      require(crowdSaleStarted,"crowdSale Not started yet");
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
    constructor(address _newOwner, address payable _wallet, Swan _token,uint256 _ethPriceInCents) Owned(_newOwner) public {
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
     revert("Caller is Owner Itself");
     }
     
    }

    //@notice returns the total Swan Tokens balance of Crowdsale Contract
    function getSwanTokenBalance() public view returns(uint256){
      return Swan(token).balanceOf(address(this));
    }

    //@notice returns the total Wei Amount raised till date
    function getTotalWeiRaised() external view returns(uint256){
      return totalWeiRaised;
    }
    
    /**
    * @dev whitelist addresses of investors.
    * @param addrs ,array of addresses of investors to be whitelisted
    * Note:= Array length must be less than 200.
    */
    function authorizeKyc(address[] calldata addrs) external onlyOwner returns (bool success) {
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
    
    function pause() external onlyOwner {
      require(!Paused,"contract is already Paused");
      require(crowdSaleStarted,"Crowdsale did not start yet");
      previousStage=currentStage;
      currentStage=Stages.Pause;
      Paused = true;
    }
  
    function restartSale() external onlyOwner {
      require(currentStage == Stages.Pause,"currentStage is not PAUSE");
      currentStage=previousStage;
      Paused = false;
    }

    function startPrivateSale() external onlyOwner {
      require(!crowdSaleStarted,"Crowdsale Already Started");
      crowdSaleStarted = true;
      currentStage = Stages.PrivateSaleStart;
    }

    function endPrivateSale() external onlyOwner {
      require(currentStage == Stages.PrivateSaleStart,"Crowdsale didn't Start yet");
      currentStage = Stages.PrivateSaleEnd;
    }

    function startPreSale() external onlyOwner {
    require(currentStage == Stages.PrivateSaleEnd,"Private Sale Didn't end yet");
    currentStage = Stages.PreSaleStart;
    }

    function endPreSale() external onlyOwner {
    require(currentStage == Stages.PreSaleStart,"Pre Sale didn't Start yet");
    currentStage = Stages.PreSaleEnd;
    }

    function startCrowdSaleRoundOne() external onlyOwner {
    require(currentStage == Stages.PreSaleEnd,"Pre Sale Didn't end yet");
    currentStage = Stages.CrowdSaleRoundOneStart;
    }

    function endCrowdSaleRoundOne() external onlyOwner {
    require(currentStage == Stages.CrowdSaleRoundOneStart,"CrowdSaleRoundOne Didn't start yet");
    currentStage = Stages.CrowdSaleRoundOneEnd;
    }

    function startCrowdSaleRoundTwo() external onlyOwner {
    require(currentStage == Stages.CrowdSaleRoundOneEnd,"CrowdSaleRoundOne Didn't end yet");
    currentStage = Stages.CrowdSaleRoundTwoStart;
    }

    function endCrowdSaleRoundTwo() external onlyOwner {
    require(currentStage == Stages.CrowdSaleRoundTwoStart,"CrowdSaleRoundTwo Didn't start yet");
    currentStage = Stages.CrowdSaleRoundTwoEnd;
    }

    function startCrowdSaleRoundThree() external onlyOwner {
    require(currentStage == Stages.CrowdSaleRoundTwoEnd,"CrowdSaleRoundTwo Didn't end yet");
    currentStage = Stages.CrowdSaleRoundThreeStart;
    }

    function endCrowdSaleRoundThree() external onlyOwner {
    require(currentStage == Stages.CrowdSaleRoundThreeStart,"CrowdSaleRoundThree Didn't start yet");
    currentStage = Stages.CrowdSaleRoundThreeEnd;
    }

    function startCrowdSaleRoundFour() external onlyOwner {
    require(currentStage == Stages.CrowdSaleRoundThreeEnd,"CrowdSaleRoundThree Didn't end yet");
    currentStage = Stages.CrowdSaleRoundFourStart;
    }

    function endCrowdSaleRoundFour() external onlyOwner {
    require(currentStage == Stages.CrowdSaleRoundFourStart,"CrowdSaleRoundFour Didn't start yet");
    currentStage = Stages.CrowdSaleRoundFourEnd;
    }

    function getStage() external view returns (string memory) {
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
   function setEthPriceInCents(uint _ethPriceInCents) onlyOwner external returns(bool) {
        ethPrice = _ethPriceInCents;
        return true;
    }

   /**
   * @param _beneficiary Address performing the token purchase
   */
   function buyTokens(address _beneficiary) CrowdsaleStarted whenNotPaused public payable {

    require(whitelistedContributors[_beneficiary] == true, "Not a whitelistedInvestor");
    require(!Paused, "Contract is Paused");
    uint256 weiAmount = msg.value;
    uint256 usdCents = weiAmount.mul(ethPrice).div(1 ether); 

    _preValidatePurchase(usdCents);

    uint256 tokens = _getTokenAmount(usdCents);

    _validateTokenCapLimits(usdCents);

    _processPurchase(_beneficiary,tokens);
    totalWeiRaised = totalWeiRaised.add(msg.value);
    wallet.transfer(msg.value);

    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
   }
  
   /**
   * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
   * @param _usdCents Value in usdincents involved in the purchase
   */
   function _preValidatePurchase(uint256 _usdCents) internal pure { 
      require(_usdCents >= minimumInvestment && _usdCents <= maximumInvestment,"_preValidatePurchase failed");
    }
    
    /**
    * @dev Validation of the capped restrictions.
    * @param _tokenValue amount
    */
    function _validateTokenCapLimits(uint256 _tokenValue) internal {
     
    if (currentStage == Stages.PrivateSaleStart) {
        
        require(privateSaletokenSold.add(_tokenValue) <= privateSaletokenLimit,"PrivateSaleStart conditions Failed");
        privateSaletokenSold = privateSaletokenSold.add(_tokenValue);
        
    }

    else if (currentStage == Stages.PreSaleStart) {
        
        require(preSaleTokensSold.add(_tokenValue) <= preSaleTokensLimit,"PreSaleStart conditions Failed");
        preSaleTokensSold = preSaleTokensSold.add(_tokenValue);
        
    }

    else if (currentStage == Stages.CrowdSaleRoundOneStart) {
        
        require(crowdSaleRoundOne.add(_tokenValue) <= crowdSaleRoundOneLimit,"CrowdSaleRoundOneStart conditions Failed");
        crowdSaleRoundOne = crowdSaleRoundOne.add(_tokenValue);        
        
    }

    else if (currentStage == Stages.CrowdSaleRoundTwoStart) {
        
        require(crowdSaleRoundTwo.add(_tokenValue) <= crowdSaleRoundTwoLimit,"CrowdSaleRoundTwoStart conditions Failed");
        crowdSaleRoundTwo = crowdSaleRoundTwo.add(_tokenValue);        
        
    }

    else if (currentStage == Stages.CrowdSaleRoundThreeStart) {
        
        require(crowdSaleRoundThree.add(_tokenValue) <= crowdSaleRoundThreeLimit,"CrowdSaleRoundThreeStart conditions Failed");
        crowdSaleRoundThree = crowdSaleRoundThree.add(_tokenValue);        
        
    }

    else if (currentStage == Stages.CrowdSaleRoundFourStart) {
        
        require(crowdSaleRoundFour.add(_tokenValue) <= crowdSaleRoundFourLimit,"CrowdSaleRoundFourStart conditions Failed");
        crowdSaleRoundFour = crowdSaleRoundFour.add(_tokenValue);        

    }    

    else { revert("No active Sale");}

   }
   /**
   * @dev Executed when a purchase has been validated and is ready to be executed.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
   function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    require(token.transfer(_beneficiary, _tokenAmount),"Transfer Failed");
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
    function finalizeSale() external  onlyOwner {
      require(currentStage == Stages.CrowdSaleRoundFourEnd,"CrowdSaleRoundFour didn't end yet");
      uint256 availableTokens = getSwanTokenBalance();
      if(availableTokens > 0){
        require(token.transfer(owner, availableTokens),"Transfer Failed");
      }else{
        revert("Zero Tokens Left in Contract");
      }
    }
}
