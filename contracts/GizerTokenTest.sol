pragma solidity ^0.4.16;

import 'GizerToken.sol';

contract GizerTokenTest is GizerToken {

  /*

  Introduces function setTestTime(uint)
  
  Overrides function atNow() to return testTime instead of now()
  
  For testing purposes, the constants CUTOFF_PRESALE_ONE, CUTOFF_PRESALE_TWO 
  and CUTOFF_ICO_ONE can also be modified in the parent contract

  */

  uint public testTime = 1;
  
  // Events ---------------------------

  event TestTimeSet(uint _now);

  // Functions ------------------------

  function GizerTokenTest() {}

  function atNow() constant returns (uint) {
      return testTime;
  }

  function setTestTime(uint _t) onlyOwner {
    require( _t > testTime ); // to avoid errors during testing
    testTime = _t;
    TestTimeSet(_t);
  }  

}
