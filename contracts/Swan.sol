pragma solidity 0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Swan is ERC20,Ownable{
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    
    constructor() public Ownable(){
        name = "Swan Finance";
        symbol = "SWAN";
        _mint(owner(), 50000000000 ether);
    }
}
