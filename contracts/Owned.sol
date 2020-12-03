pragma solidity 0.5.16;
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

  function acceptOwnership() public {
      require(msg.sender == newOwner);
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
      newOwner = address(0);
  }
}