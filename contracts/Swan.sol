pragma solidity 0.5.16;

import "./Owned.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract Swan is Owned, ERC20Detailed, ERC20 {
    constructor(address _owner)
        public
        ERC20Detailed("Swan Finance", "SWAN", 18)
        Owned(_owner)
    {
        _mint(_owner, 50000000000 * (10**uint256(decimals())));
    }
}
