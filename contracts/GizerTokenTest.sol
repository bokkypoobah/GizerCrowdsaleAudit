pragma solidity ^0.4.16;

import 'GizerToken.sol';

contract GizerTokenTest is GizerToken {

  /*

  Introduces function setTestTime(uint)
  
  Overrides function atNow() to return testTime instead of now()
  
  Overrides constants CUTOFF_PRESALE_ONE, CUTOFF_PRESALE_TWO and 
  CUTOFF_ICO_ONE for easier testing

  */

  uint public testTime = 1;
  
  uint public constant CUTOFF_PRESALE_ONE = 2;
  uint public constant CUTOFF_PRESALE_TWO = 4;
  uint public constant CUTOFF_ICO_ONE     = 2;

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
