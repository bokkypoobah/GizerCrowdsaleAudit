# GZR development tests

1 - Basic tests: wallet change, whitelist and ICO date change functions

2 - Crowdsale fail

3 - Crowdsale success

All tests were done using the GizerTokenTest contract on a local Parity development chain, with the following modifications to the GizerToken contract:

  uint public constant CUTOFF_PRESALE_ONE = 2; // last contributor wave 1
  
  uint public constant CUTOFF_PRESALE_TWO = 4; // last contributor wave 2
  
  uint public constant CUTOFF_ICO_ONE = 2; // last contributor wave 1

 The Ruby source code is as yet not properly documented and provided here just to provide a general idea. The sLog_x.log file provide a log of the actions, expected results and differences of state resulting from the actions. The state_x.txt files contain the ending state of relevant contract variables as well as the maps for 20 accounts used in testing.
