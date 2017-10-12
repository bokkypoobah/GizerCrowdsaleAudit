# Gizer Crowdsale And Token Contract Audit

## Summary

Commits
[3198d0e](https://github.com/GizerInc/crowdsale/commit/3198d0e0c38a9103554e56734c1c9e63f941dc57),
[c1e4255](https://github.com/GizerInc/crowdsale/commit/c1e4255f8de001f5eb271a9f6598bd3f12e57fe6),
[43b4d51](https://github.com/GizerInc/crowdsale/commit/43b4d51b0ca1268e72b69ad66cc3b6f612e31fdb) and
[9ed59cc](https://github.com/GizerInc/crowdsale/commit/9ed59cc458a0b1f9c369f51f609c657f199b355a).

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

  * [x] Updated in [9ed59cc](https://github.com/GizerInc/crowdsale/commit/9ed59cc458a0b1f9c369f51f609c657f199b355a)

* **LOW IMPORTANCE** `GizerToken.GizerToken()` does not need the statement `owner = msg.sender;` as this assignment is already
  made in `Owned.Owned()`

  * [x] Fixed in [43b4d51](https://github.com/GizerInc/crowdsale/commit/43b4d51b0ca1268e72b69ad66cc3b6f612e31fdb)

* **MEDIUM IMPORTANCE** Token balances for all the accounts should add up to the `totalSupply`. Currently the different
  token allocations do not add up to `TOTAL_TOKEN_SUPPLY`. At least the known allocations should be represented in this token contract

* **MEDIUM IMPORTANCE** Any changes to the `balances[...]` mapping should have a related `Transfer(...)` event. When these transfers
  are displayed in EtherScan.io or Ethplorer.io, the accounting should balance. Minted tokens should have a `Transfer(0x0, ...)` event

* **LOW IMPORTANCE** The comment [https://github.com/ethereum/EIPs/issues/20](https://github.com/ethereum/EIPs/issues/20) should
  be updated to the final standard at [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md)

  * [x] Updated in [9ed59cc](https://github.com/GizerInc/crowdsale/commit/9ed59cc458a0b1f9c369f51f609c657f199b355a)

* **MEDIUM IMPORTANCE** In `setRedemptionWallet(...)`, `RedemptionWalletUpdated(wallet);` should be `RedemptionWalletUpdated(redemptionWallet);`

  * [x] Fixed in [9ed59cc](https://github.com/GizerInc/crowdsale/commit/9ed59cc458a0b1f9c369f51f609c657f199b355a)

* **MEDIUM IMPORTANCE** In `setWhitelistWallet(...)`, `WhitelistWalletChanged(wallet);` should be `WhitelistWalletChanged(whitelistWallet);`

  * [x] Fixed in [9ed59cc](https://github.com/GizerInc/crowdsale/commit/9ed59cc458a0b1f9c369f51f609c657f199b355a)

* **LOW IMPORTANCE** The logic in `isWhitelisted(...)` can be simplified, and this function can be removed and replaced by setting `whitelist` 
  to public visibility. See the NOTEs in the code review

  * [x] Updated in [9ed59cc](https://github.com/GizerInc/crowdsale/commit/9ed59cc458a0b1f9c369f51f609c657f199b355a)

* **LOW IMPORTANCE** `DATE_ICO_START` and `DATE_ICO_END` are not constants and should be camelCased

* **LOW IMPORTANCE** In `approve(...)`, consider removing `require( _amount == 0 || allowed[msg.sender][_spender] == 0 );` as this is no
  longer recommended in [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md):

  > THOUGH The contract itself shouldn't enforce it, ...

<br />

<hr />

## Code Review

* [ ] [code-review/GizerTokenSale.md](code-review/GizerTokenSale.md)
  * [x] library SafeMath3
  * [x] contract Owned
  * [x] contract ERC20Interface
  * [x] contract ERC20Token is ERC20Interface, Owned
  * [ ] contract GizerToken is ERC20Token
