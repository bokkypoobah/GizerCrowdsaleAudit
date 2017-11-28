# Gizer Crowdsale And Token Contract Audit

## Summary

[Gizer](https://gizer.io/) intends to run a crowdsale commencing in Nov 2017.

Bok Consulting Pty Ltd was commissioned to perform an audit on Gizer's crowdsale and token Ethereum smart contract.

This audit was originally conducted on Gizer's Presale + Crowdsale source code in commits
[3198d0e](https://github.com/GizerInc/crowdsale/commit/3198d0e0c38a9103554e56734c1c9e63f941dc57),
[c1e4255](https://github.com/GizerInc/crowdsale/commit/c1e4255f8de001f5eb271a9f6598bd3f12e57fe6),
[43b4d51](https://github.com/GizerInc/crowdsale/commit/43b4d51b0ca1268e72b69ad66cc3b6f612e31fdb),
[9ed59cc](https://github.com/GizerInc/crowdsale/commit/9ed59cc458a0b1f9c369f51f609c657f199b355a) and
[50cfcec](https://github.com/GizerInc/crowdsale/commit/50cfcec87a17a7a67012b72c89973aa78e1924c6).

No potential vulnerabilities have been identified in the original crowdsale and token contract.

<br />

**Nov 28 2017** - The presale and token contract was later separated out in commit
[1bff114](https://github.com/GizerInc/crowdsale/commit/1bff1142c52c416e077a03aa32fe33450e0e842d).

No potential vulnerabilities have been identified in the new presale and token contract.

<br />

### Presale Contract

* Ethers (ETH) contributed to the presale contract are immediately moved to the crowdsale `wallet`

<br />

### Presale Token Contract

* The tokens will only be transferable into the `redemptionWallet`, before the tokens are frozen
* The tokens can be frozen by the contract owner. The intention here is for the presale token balances to be frozen,
  and the presale token balance will then be used to generate the crowdsale token contract balances

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
  * [Presale Contract](#presale-contract)
  * [Presale Token Contract](#presale-token-contract)
* [Recommendations](#recommendations)
* [Potential Vulnerabilities](#potential-vulnerabilities)
* [Scope](#scope)
* [Limitations](#limitations)
* [Due Diligence](#due-diligence)
* [Risks](#risks)
* [Testing](#testing)
  * [Test 1 Success](#test-1-success)
  * [Test 2 Refunds](#test-2-refunds)
* [Code Review](#code-review)

<br />

<hr />

## Recommendations

### First Review

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
  * [x] Updated in [9ed59cc](https://github.com/GizerInc/crowdsale/commit/9ed59cc458a0b1f9c369f51f609c657f199b355a)
* **MEDIUM IMPORTANCE** Any changes to the `balances[...]` mapping should have a related `Transfer(...)` event. When these transfers
  are displayed in EtherScan.io or Ethplorer.io, the accounting should balance. Minted tokens should have a `Transfer(0x0, ...)` event
  * [x] Updated in [9ed59cc](https://github.com/GizerInc/crowdsale/commit/9ed59cc458a0b1f9c369f51f609c657f199b355a)
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
  * [x] Fixed in [50cfcec](https://github.com/GizerInc/crowdsale/commit/50cfcec87a17a7a67012b72c89973aa78e1924c6)
* **LOW IMPORTANCE** In `approve(...)`, consider removing `require( _amount == 0 || allowed[msg.sender][_spender] == 0 );` as this is no
  longer recommended in [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md):
  > THOUGH The contract itself shouldn't enforce it, ...
  * [x] Fixed in [50cfcec](https://github.com/GizerInc/crowdsale/commit/50cfcec87a17a7a67012b72c89973aa78e1924c6)

<br />

## New Presale Only Contract

Added in commit [1bff114](https://github.com/GizerInc/crowdsale/commit/1bff1142c52c416e077a03aa32fe33450e0e842d).

* **LOW IMPORTANCE** `Owned.acceptOwnership()` will log the event when `owner` has already been assigned to `newOwner`
* **LOW IMPORTANCE** The `require(...)` statements in `transfer(...)` and `transferFrom(...)` are redundant as the
  *SafeMath* library function will `REVERT` if the numbers cause a problem. It is your preference whether the `require(...)`
  statements are used or not
* **LOW IMPORTANCE** `privateSaleContribution(...)` will be called by the owner to add contribution entries without any ethers
  being sent. This function calls `issueTokens(...)` which executes `wallet.transfer(this.balance);` at the end. Place a check
  `if (this.balance > 0) { ... }` around the `wallet.transfer(this.balance);` statement

<br />

<hr />

## Potential Vulnerabilities

No potential vulnerabilities have been identified in the crowdsale and token contract.

<br />

<hr />

## Scope

This audit is into the technical aspects of the crowdsale contracts. The primary aim of this audit is to ensure that funds
contributed to these contracts are not easily attacked or stolen by third parties. The secondary aim of this audit is that
ensure the coded algorithms work as expected. This audit does not guarantee that that the code is bugfree, but intends to
highlight any areas of weaknesses.

<br />

<hr />

## Limitations

This audit makes no statements or warranties about the viability of the Gizer's business proposition, the individuals
involved in this business or the regulatory regime for the business model.

<br />

<hr />

## Due Diligence

As always, potential participants in any crowdsale are encouraged to perform their due diligence on the business proposition
before funding any crowdsales.

Potential participants are also encouraged to only send their funds to the official crowdsale Ethereum address, published on
the crowdsale beneficiary's official communication channel.

Scammers have been publishing phishing address in the forums, twitter and other communication channels, and some go as far as
duplicating crowdsale websites. Potential participants should NOT just click on any links received through these messages.
Scammers have also hacked the crowdsale website to replace the crowdsale contract address with their scam address.
 
Potential participants should also confirm that the verified source code on EtherScan.io for the published crowdsale address
matches the audited source code, and that the deployment parameters are correctly set, including the constant parameters.

<br />

<hr />

## Risks

* Contributed ethers will accummulate in this crowdsale contract until the minimum funding level is reached. In the case where the minimum
  funding level is not reached, refunds are provided to participants. Once this minimum funding level is reached, all contributed ether is
  be immediately transferred to an external wallet.

<br />

<hr />

## Testing

### Test 1 Success

The following functions were tested using the script [test/01_test1.sh](test/01_test1.sh) with the summary results saved
in [test/test1results.txt](test/test1results.txt) and the detailed output saved in [test/test1output.txt](test/test1output.txt):

* [x] Deploy the crowdsale/token contract
* [x] Change wallets
* [x] Whitelist participant accounts
* [x] Contribute in the presale stage
* [x] Contribute in the crowdsale stage
* [x] Finalise the crowdsale
* [x] Transfer tokens

<br />

### Test 2 Refunds

The following functions were tested using the script [test/02_test2.sh](test/02_test2.sh) with the summary results saved
in [test/test2results.txt](test/test2results.txt) and the detailed output saved in [test/test2output.txt](test/test2output.txt):

* [x] Deploy the crowdsale/token contract
* [x] Change wallets
* [x] Whitelist participant accounts
* [x] Contribute in the presale stage
* [x] Contribute in the crowdsale stage
* [x] Claim refunds

<br />

Details of the testing environment can be found in [test](test).

<br />

<hr />

## Code Review

### First Review

* [ ] [code-review/GizerToken.md](code-review/GizerToken.md)
  * [x] library SafeMath
  * [x] contract Owned 
  * [x] contract ERC20Interface 
  * [x] contract ERC20Token is ERC20Interface, Owned 
  * [x] contract GizerToken is ERC20Token 

<br />

### Second Review With The Presale Only Contract

* [x] [code-review/GizerTokenPresale.md](code-review/GizerTokenPresale.md)
  * [x] library SafeMath
  * [x] contract Owned
  * [x] contract ERC20Interface
  * [x] contract ERC20Token is ERC20Interface, Owned
  * [x] contract GizerTokenPresale is ERC20Token

<br />

<br />

(c) BokkyPooBah / Bok Consulting Pty Ltd for Gizer - Nov 7 2017. The MIT Licence.