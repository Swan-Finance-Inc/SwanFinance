pragma solidity 0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Swan is ERC20,Pausable,Ownable{
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public teamMemberHrWallet = 5000000000 ether;

    mapping(address => uint256) public teamTokensLeft;

    bool public contractSaleOver = false;
    uint256 public contractSaleOverTime;

    constructor() public Ownable() {
        name = "Swan Finance";
        symbol = "SWAN";
        _mint(owner(), 50000000000 ether);
    }

    function transfer(address recipient, uint256 amount)
        public
        whenNotPaused
        returns (bool)
    {
        super._transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        super.transferFrom(sender, recipient, amount);

        return true;
    }
}
