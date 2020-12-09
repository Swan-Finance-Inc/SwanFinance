pragma solidity 0.5.16;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed _to);

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is Not the OWNER");
        _;
    }

    function transferOwnership(address newOwnerAddress) external onlyOwner {
        require(
            newOwnerAddress != address(0),
            "Invalid Address: New owner is the zero address"
        );
        newOwner = newOwnerAddress;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner, "Caller is not the selected Owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
