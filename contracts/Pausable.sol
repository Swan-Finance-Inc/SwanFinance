pragma solidity 0.5.16;
import "./Owned.sol";
contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
      require(!paused);
      _;
    }

    modifier whenPaused() {
      require(paused);
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