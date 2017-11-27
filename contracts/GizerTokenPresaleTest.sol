pragma solidity ^0.4.17;

import 'GizerTokenPresale.sol';

contract GizerTokenPresaleTest is GizerTokenPresale {

  /*

  Introduces function setTestTime(uint)
  
  Overrides function atNow() to return testTime instead of now()
  
  For testing purposes, the constants CUTOFF_PRESALE_ONE, CUTOFF_PRESALE_TWO 
  can also be modified in the parent contract

  */

  uint public testTime = 1;
  
  // Events ---------------------------

  event TestTimeSet(uint _now);

  // Functions ------------------------

  function GizerTokenPresaleTest() public {}

  function atNow() public view returns (uint) {
      return testTime;
  }

  function setTestTime(uint _t) public onlyOwner {
    require( _t > testTime ); // to avoid errors during testing
    testTime = _t;
    TestTimeSet(_t);
  }  

}
