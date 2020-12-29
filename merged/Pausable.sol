pragma solidity 0.5.16;


contract Owned {
    address public owner;
    address public nominatedOwner;

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }
}

contract Pausable is Owned {
    uint private lastPauseTime;
    bool private paused;

    event Pause(bool isPaused);
    event Unpause(bool isPaused);

    constructor() internal {
    require(owner != address(0), "Owner must be set");
  }

    modifier whenNotPaused() {
      require(!paused,"Contract is Paused");
      _;
    }

    modifier whenPaused() {
      require(paused,"Contract is Not Paused");
      _;
    }

    function isPaused() public view returns(bool) {
        return paused;
    }

    function getLastPauseTime () public view returns(uint256){
    	return lastPauseTime;	
    }
    
    function pause() onlyOwner whenNotPaused external {
      paused = true;
      lastPauseTime = now;
      emit Pause(paused);
    }

    function unpause() onlyOwner whenPaused external {
      paused = false;
      emit Unpause(paused);
    }
}