pragma solidity 0.5.16;

import "./Owned.sol";
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