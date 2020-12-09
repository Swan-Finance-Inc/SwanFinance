// pragma solidity ^0.5.16;

// import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
// import "./Owned.sol";
// import "./SwanStake.sol";

// contract SwanEarn is Owned{
//   using SafeERC20 for IERC20;
//   using Address for address;

//   SwanStake stakingContract;

//   // Includes details about further major or minor stakes by a user in order to earn interest
//   struct DepositItem
//   {
//     uint256 index;
//     uint256 amount;
//     uint256 depositTime;
//     uint256 expireTime;
//     uint depositPeriod;
//     uint interestRate;
//     uint256 lastInterestClaimedTime;
//   }

//   struct Depositor {
//     bool isDepositor;
//     uint256 numOfDeposited;
//     DepositItem[] depositItems;
//   }

//   mapping(address => Depositor) public depositorMap;
//   address[] private depositorAddress;

//   /**
//     * @dev emitted whenever user make a lock
//   */
//   event deposit(address indexed _user, uint256 _depositAmount, uint _depositPeriod, uint _interestRate, uint256 _depositTime);
//   event claim(address indexed _user, uint256 _claimedInterestAmount, uint256 _claimTime);
//   event withdrawn(address indexed _user, uint256 _depositTime, uint256 _depositAmount, uint _depositPeriod, uint _interestRate, uint256 _witdhrawTime);

//   constructor(address _owner, SwanStake _stakingContract) public Owned(_owner) {
//     stakingContract = _stakingContract;
//   }


//   function getDepositData() external view Owned(_owner){
//     return depositorMap;
//   }

//   function depositETH(uint256 _depositPeriod) external payable{
//     // Check if the msg.sender's swan token stacked status
//     // If this is more than $2000 then initial interest rate from 4 to 8
//     uint256 userSwanStackedAmount = stakingContract.getUserStakedAmount(msg.sender);
//     uint _interestRate = 4 + userSwanStackedAmount > 2000 ether ? 4 : 0;

//     if (depositorMap[msg.sender].isDepositor == false) {
//       depositorAddress.push(msg.sender);
//       depositorMap[msg.sender].isDepositor = true;
//     }

//     depositorMap[msg.sender].numOfDeposited ++;
//     depositorMap[msg.sender].depositItems.push(DepositItem({
//       index: depositorMap[msg.sender].numOfDeposited-1,
//       amount: msg.value,
//       depositTime: block.timestamp,
//       lastInterestClaimedTime: block.timestamp,
//       interestRate: _interestRate,
//       depositPeriod: _depositPeriod,
//       expireTime: SafeMath.add(block.timestamp, SafeMath.mul(2592000, period))
//     }));

//     emit deposit(msg.sender, msg.value, _depositPeriod, _interestRate, block.timestamp);
//   }

//   function claimInterestETH(uint256 _index) external {
//     require(depositorMap[msg.sender].isDepositor, "You should deposit first!");
//     require(depositorMap[msg.sender].numOfDeposited > _index, "You should deposit first!");

//     DepositItem memory depositItem = depositorMap[msg.sender].depositItems[_index];

//     // Check if the deposit period is expired.
//     uint256 timeLimit = block.time;
//     if(timeLimit > depositItem.expireTime) {
//       timeLimit = depositItem.expireTime;
//     }

//     uint256 numOfWeeks = SafeMath.div(SafeMath.sub(timeLimit - depositItem.lastInterestClaimedTime), 604800); // Passed weeks
//     require(numOfWeeks > 0, "You should wait at least 1 week!");
//     uint256 interestAmount = SafeMath.mul(SafeMath.div(SafeMath.mul(depositItem.amount, depositItem.interestRate), 100), numOfWeeks);

//     require(balanceOf(address(this)) >= interestAmount, "No enough balance in contract!");
//     address(this).transfer(interestAmount);

//     depositItem.lastInterestClaimedTime = SafeMath.add(depositItem.lastInterestClaimedTime, SafeMath.mul(604800, numOfWeeks));
//     depositorMap[msg.sender].depositItems[_index] = depositItem;

//     emit claim(msg.sender, interestAmount, block.timestamp);
//   }

//   function withdrawDepositETH(uint256 _index) external {
//     // Claim the interest if have any
//     claimInterestETH(_index);
//     DepositItem memory depositItem = depositorMap[msg.sender].depositItems[_index];

//     require(balanceOf(address(this)) >= depositItem.amount, "No enough balance in contract!");
//     address(this).transfer(depositItem.amount);
//     // After successful withdraw remove the deposit item.
//     for(uint i = _index; i < depositorMap[msg.sender].depositItems.length - 1;i ++) {
//       depositorMap[msg.sender].depositItems[i] = depositorMap[msg.sender].depositItems[i + 1];
//     }
//     depositorMap[msg.sender].depositItems.length --;

//     emit widthdrawn(msg.sender, depositItem.depositTime, depositItem.amount, depositItem.depositPeriod, depositItem.interestRate, block.timestamp);
//   }
// }