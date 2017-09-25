# Gizer Crowdsale And Token Contract Audit

## Summary

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Recommendations](#recommendations)
* [Code Review](#code-review)

<br />

<hr />

## Recommendations

* **LOW IMPORTANCE** Please reformat the code and comments to make it easier to read the code. Some inconsistencies:

  * Variable comment styles makes it hard to pick out the different sections, functions, variables, events:

        // events -------------------------

        // VARIABLES ================================

        // utility variable

        // Allow _spender to withdraw from your account up to_amount.
        //

        // --------------------------------
        // implement totalSupply() ERC20 function
        // --------------------------------

    It is easier to read "Events" than "events" or "VARIABLES"

  * Brackets and spacings:

        require( _amount > 0 );

        require( _amount == 0 || allowed[msg.sender][_spender] == 0 );

        require (balances[msg.sender] >= _amount);

        require( balances[_participant] == 0 || locked[_participant] != true);

  * Don't need `LogXxx` for events as the standard convention is just to use Xxx
  * Sometimes there is one blank line before function declarations, sometimes none

* **LOW IMPORTANCE** `GizerToken.GizerToken()` does not need the statement `owner = msg.sender;` as this assignment is already
  made in `Owned.Owned()`

* **MEDIUM IMPORTANCE** Token balances for all the accounts should add up to the `totalSupply`. Currently the different
  token allocations do not add up to `TOTAL_TOKEN_SUPPLY`. At least the known allocations should be represented in this token contract

* **MEDIUM IMPORTANCE** Any changes to the `balances[...]` mapping should have a related `Transfer(...)` event. When these transfers
  are displayed in EtherScan.io or Ethplorer.io, the accounting should balance. Minted tokens should have a `Transfer(0x0, ...)` event

<br />

<hr />

## Code Review

* [ ] [code-review/GizerTokenSale.md](code-review/GizerTokenSale.md)
  * [ ] contract Owned 
  * [ ] contract ERC20Interface 
  * [ ] contract ERC20Token is ERC20Interface, Owned 
  * [ ] contract GizerToken is ERC20Token
