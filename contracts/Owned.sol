pragma solidity 0.5.16;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Owned.sol";
import "./SwanStake.sol";

contract SwanEarn is Owned{
  using SafeERC20 for IERC20;
  using Address for address;

  SwanStake stakingContract;
  IERC20 public usdt;

  // Includes details about further major or minor stakes by a user in order to earn interest
  struct LockAccount
  {
    uint256 amount;
    string currency;
    uint256 time;
    uint256 interestRate;
    uint256 interestPayouts;
    uint256 timeperiod;
    bool withdrawn;
  }
  mapping(address => mapping(uint256 => LockAccount)) public lockedUSDTData;
  mapping(address => LockAccount[]) public lockedETHData;
  address[] private lockedUserAddress;
  /**
    * @dev emitted whenever user make a lock
  */
  event deposit(address indexed _user, uint256 _amount, uint256 _lockupPeriod, uint256 _interest);

  constructor(address _owner, SwanStake _stakingContract) public Owned(_owner) {
    usdt = IERC20('0xdac17f958d2ee523a2206206994597c13d831ec7');
    stakingContract = _stakingContract;
  }

  function depositETH() external payable{
    userETHStakes[msg.sender] = userETHStakes[msg.sender].add(msg.value);
  }

  function depositUSDT(uint256 amount, uint256 period) external {
    require(usdt.safeTransferFrom(msg.sender, address(this), amount), "Don't have enough balance");

    // Check if the msg.sender's swan token stacked status
    // If this is more than 2000 then initial interest rate from 4 to 8

    userSwanStackedAmount = stakingContract.getUserStackedAmount(msg.sender);

    _interestRate = 4 + userSwanStackedAmount > 2000 ether ? 4 : 0;
    timeStamp = now;
    lockedUSDTData[msg.sender][timeStamp](LockAccount({
      amount: _amount,
      currency: "USDT",
      time: timeStamp,
      interestRate: _interestRate,
      interestPayouts: 0,
      timeperiod: period,
      withdrawn: false,
    }));

    emit deposit(msg.sender, _amount, period, _interestRate);
  }

  /**
    * @dev This will be called everyday. Check the locked data and make the payout
  */
  function calculateInterest() external {

  }

  function claimInterest() external {

    require(stackedUSD)
  }
}