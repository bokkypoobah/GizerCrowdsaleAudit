# GizerTokenPresale

Source file [../../contracts/GizerTokenPresale.sol](../../contracts/GizerTokenPresale.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
//
// GZR 'Gizer Gaming' token presale contract
//
// For details, please visit: http://www.gizer.io
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// SafeMath (div not needed but kept for completeness' sake)
//
// ----------------------------------------------------------------------------

// BK Ok
library SafeMath {

  // BK Ok
  function add(uint a, uint b) public pure returns (uint c) {
    // BK Ok
    c = a + b;
    // BK Ok
    require( c >= a );
  }

  // BK Ok
  function sub(uint a, uint b) public pure returns (uint c) {
    // BK Ok
    require( b <= a );
    // BK Ok
    c = a - b;
  }

  // BK Ok
  function mul(uint a, uint b) public pure returns (uint c) {
    // BK Ok
    c = a * b;
    // BK Ok
    require( a == 0 || c / a == b );
  }

  // BK Ok
  function div(uint a, uint b) public pure returns (uint c) {
    // BK Ok
    c = a / b;
  }  

}


// ----------------------------------------------------------------------------
//
// Owned contract
//
// ----------------------------------------------------------------------------

// BK Ok
contract Owned {

  // BK Next 2 Ok
  address public owner;
  address public newOwner;

  // Events ---------------------------

  // BK Next 2 Ok - Events
  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);

  // Modifier -------------------------

  // BK Ok
  modifier onlyOwner {
    // BK Ok
    require( msg.sender == owner );
    // BK Ok
    _;
  }

  // Functions ------------------------

  // BK Ok - Constructor
  function Owned() public {
    // BK Ok
    owner = msg.sender;
  }

  // BK Ok - Only owner can execute
  function transferOwnership(address _newOwner) public onlyOwner {
    // BK Ok
    require( _newOwner != owner );
    // BK Ok
    require( _newOwner != address(0x0) );
    // BK Ok
    newOwner = _newOwner;
    // BK Ok
    OwnershipTransferProposed(owner, _newOwner);
  }

  // BK Ok - Only new owner can execute
  function acceptOwnership() public {
    // BK Ok
    require( msg.sender == newOwner );
    // BK Ok
    owner = newOwner;
    // BK NOTE - Both values are the same below
    OwnershipTransferred(owner, newOwner);
  }

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
// ----------------------------------------------------------------------------

// BK Ok
contract ERC20Interface {

  // Events ---------------------------

  // BK Next 2 Ok - Events
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  // Functions ------------------------

  // BK Next 6 Ok
  function totalSupply() public view returns (uint);
  function balanceOf(address _owner) public view returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) public view returns (uint remaining);

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// ----------------------------------------------------------------------------

// BK Ok
contract ERC20Token is ERC20Interface, Owned {
  
  // BK Ok
  using SafeMath for uint;

  // BK Ok
  uint public tokensIssuedTotal = 0;
  // BK Next 2 Ok
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  // Functions ------------------------

  /* Total token supply */

  // BK Ok - View function
  function totalSupply() public view returns (uint) {
    // BK Ok
    return tokensIssuedTotal;
  }

  /* Get the account balance for an address */

  // BK Ok - View function
  function balanceOf(address _owner) public view returns (uint balance) {
    // BK Ok
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  // BK Ok
  function transfer(address _to, uint _amount) public returns (bool success) {
    // amount sent cannot exceed balance
    // BK NOTE - Next line not required as SafeMath will revert if the are insufficient tokens, but OK to leave in
    // BK Ok
    require( balances[msg.sender] >= _amount );

    // update balances
    // BK Ok
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    // BK Ok
    balances[_to]        = balances[_to].add(_amount);

    // log event
    // BK Ok - Log event
    Transfer(msg.sender, _to, _amount);
    // BK Ok
    return true;
  }

  /* Allow _spender to withdraw from your account up to _amount */

  // BK Ok
  function approve(address _spender, uint _amount) public returns (bool success) {
    // approval amount cannot exceed the balance
    // BK Ok
    require ( balances[msg.sender] >= _amount );
      
    // update allowed amount
    // BK Ok
    allowed[msg.sender][_spender] = _amount;
    
    // log event
    // BK Ok - Log event
    Approval(msg.sender, _spender, _amount);
    // BK Ok
    return true;
  }

  /* Spender of tokens transfers tokens from the owner's balance */
  /* Must be pre-approved by owner */

  // BK Ok
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    // balance checks
    // BK NOTE - Next line not required as SafeMath will revert if the are insufficient tokens, but OK to leave in
    require( balances[_from] >= _amount );
    // BK NOTE - Next line not required as SafeMath will revert if the are insufficient tokens, but OK to leave in
    require( allowed[_from][msg.sender] >= _amount );

    // update balances and allowed amount
    // BK Ok
    balances[_from]            = balances[_from].sub(_amount);
    // BK Ok
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    // BK Ok
    balances[_to]              = balances[_to].add(_amount);

    // log event
    // BK Ok - Log event
    Transfer(_from, _to, _amount);
    // BK Ok
    return true;
  }

  /* Returns the amount of tokens approved by the owner */
  /* that can be transferred by spender */

  // BK Ok - View function
  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    // BK Ok
    return allowed[_owner][_spender];
  }

}


// ----------------------------------------------------------------------------
//
// GZR token presale
//
// ----------------------------------------------------------------------------

// BK Ok
contract GizerTokenPresale is ERC20Token {

  /* Utility variables */
  
  // BK Ok
  uint constant E6  = 10**6;

  /* Basic token data */

  // BK Next 3 Ok
  string public constant name     = "Gizer Gaming Presale Token";
  string public constant symbol   = "GZRPRE";
  uint8  public constant decimals = 6;

  /* Wallets */
  
  // BK Next 2 Ok
  address public wallet;
  address public redemptionWallet;

  /* General crowdsale parameters */  
  
  // BK Next 2 Ok
  uint public constant MIN_CONTRIBUTION = 1 ether / 10; // 0.1 Ether
  uint public constant MAX_CONTRIBUTION = 100 ether;
  
  /* Private sale */

  // BK Ok
  uint public constant PRIVATE_SALE_MAX_ETHER = 1000 ether;
  
  /* Presale parameters */
  
  // BK Ok - new Date(1512050400 * 1000).toUTCString() => Thu, 30 Nov 2017 14:00:00 UTC
  uint public constant DATE_PRESALE_START = 1512050400; // 30-Nov-2017 14:00 UTC
  // BK Ok - new Date(1513260000 * 1000).toUTCString() => Thu, 14 Dec 2017 14:00:00 UTC
  uint public constant DATE_PRESALE_END   = 1513260000; // 14-Dec-2017 14:00 UTC
  
  // Next 3 Ok
  uint public constant TOKETH_PRESALE_ONE   = 1150 * E6; // presale wave 1 (  1-100)
  uint public constant TOKETH_PRESALE_TWO   = 1100 * E6; // presale wave 2 (101-500)
  uint public constant TOKETH_PRESALE_THREE = 1075 * E6; // presale - others
  
  // Next 2 Ok
  uint public constant CUTOFF_PRESALE_ONE = 100; // last contributor wave 1
  uint public constant CUTOFF_PRESALE_TWO = 500; // last contributor wave 2

  // BK Ok
  uint public constant FUNDING_PRESALE_MAX = 2250 ether;

  /* Presale variables */

  // BK Next 2 Ok
  uint public etherReceivedPrivate = 0; // private sale Ether
  uint public etherReceivedCrowd   = 0; // crowdsale Ether

  // BK Next 3 Ok
  uint public tokensIssuedPrivate = 0; // private sale tokens
  uint public tokensIssuedCrowd   = 0; // crowdsale tokens
  uint public tokensBurnedTotal   = 0; // tokens burned by owner
  
  // BK Ok
  uint public presaleContributorCount = 0;
  
  // BK Ok
  bool public tokensFrozen = false;

  /* Mappings */

  // BK Next 2 Ok
  mapping(address => uint) public balanceEthPrivate; // private sale Ether
  mapping(address => uint) public balanceEthCrowd;   // crowdsale Ether

  // BK Next 2 Ok
  mapping(address => uint) public balancesPrivate; // private sale tokens
  mapping(address => uint) public balancesCrowd;   // crowdsale tokens

  // Events ---------------------------
  
  // BK Next 4 Ok - Events
  event WalletUpdated(address _newWallet);
  event RedemptionWalletUpdated(address _newRedemptionWallet);
  event TokensIssued(address indexed _owner, uint _tokens, uint _balance, uint _tokensIssuedCrowd, bool indexed _isPrivateSale, uint _amount);
  event OwnerTokensBurned(uint _tokensBurned, uint _tokensBurnedTotal);
  
  // Basic Functions ------------------

  /* Initialize */

  // BK Ok - Constructor
  function GizerTokenPresale() public {
    // BK Next 2 Ok
    wallet = owner;
    redemptionWallet = owner;
  }

  /* Fallback */
  
  // BK Ok - Payable
  function () public payable {
    // BK Ok
    buyTokens();
  }

  // Information Functions ------------
  
  /* What time is it? */
  
  // BK Ok - View function
  function atNow() public view returns (uint) {
    // BK Ok
    return now;
  }

  // Owner Functions ------------------
  
  /* Change the crowdsale wallet address */

  // BK Ok - Only owner can execute
  function setWallet(address _wallet) public onlyOwner {
    // BK Ok
    require( _wallet != address(0x0) );
    // BK Ok
    wallet = _wallet;
    // BK Ok - Log event
    WalletUpdated(_wallet);
  }

  /* Change the redemption wallet address */

  // BK Ok - Only owner can execute
  function setRedemptionWallet(address _wallet) public onlyOwner {
    // BK Ok
    redemptionWallet = _wallet;
    // BK Ok - Log event
    RedemptionWalletUpdated(_wallet);
  }
  
  /* Issue tokens for ETH received during private sale */

  // BK Ok - Only owner can execute
  function privateSaleContribution(address _account, uint _amount) public onlyOwner {
    // checks
    // BK Ok
    require( _account != address(0x0) );
    // BK Ok
    require( atNow() < DATE_PRESALE_END );
    // BK Ok
    require( _amount >= MIN_CONTRIBUTION );
    // BK Ok
    require( etherReceivedPrivate.add(_amount) <= PRIVATE_SALE_MAX_ETHER );
    
    // same conditions as early presale participants
    // BK Ok
    uint tokens = TOKETH_PRESALE_ONE.mul(_amount) / 1 ether;
    
    // issue tokens
    // BK Ok
    issueTokens(_account, tokens, _amount, true); // true => private sale
  }

  /* Freeze tokens */
  
  // BK Ok - Only owner can execute
  function freezeTokens() public onlyOwner {
    // BK Ok
    require( atNow() > DATE_PRESALE_END );
    // BK Ok
    tokensFrozen = true;
  }
  
  /* Burn tokens held by owner */
  
  // BK Ok - Only owner can execute
  function burnOwnerTokens() public onlyOwner {
    
    // check if there is anything to burn
    // BK Ok
    require( balances[owner] > 0 );
    
    // update 
    // BK Ok
    uint tokensBurned = balances[owner];
    // BK Ok
    balances[owner] = 0;
    // BK Ok
    tokensIssuedTotal = tokensIssuedTotal.sub(tokensBurned);
    // BK Ok
    tokensBurnedTotal = tokensBurnedTotal.add(tokensBurned);
    
    // log
    // BK Next 2 Ok - Log events
    Transfer(owner, 0x0, tokensBurned);
    OwnerTokensBurned(tokensBurned, tokensBurnedTotal);

  }  

  /* Transfer out any accidentally sent ERC20 tokens */

  // BK Ok - Only owner can execute
  function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
      // BK Ok
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

  // Private functions ----------------

  /* Accept ETH during presale (called by default function) */

  // BK Ok - Private function, only called by fallback function
  function buyTokens() private {

    // initial checks
    // BK Ok
    require( atNow() > DATE_PRESALE_START && atNow() < DATE_PRESALE_END );
    // BK Ok
    require( msg.value >= MIN_CONTRIBUTION && msg.value <= MAX_CONTRIBUTION );
    // BK Ok
    require( etherReceivedCrowd.add(msg.value) <= FUNDING_PRESALE_MAX );

    // tokens
    // BK Ok
    uint tokens;
    // BK Ok
    if (presaleContributorCount < CUTOFF_PRESALE_ONE) {
      // wave 1
      // BK Ok
      tokens = TOKETH_PRESALE_ONE.mul(msg.value) / 1 ether;
    // BK Ok
    } else if (presaleContributorCount < CUTOFF_PRESALE_TWO) {
      // wave 2
      // BK Ok
      tokens = TOKETH_PRESALE_TWO.mul(msg.value) / 1 ether;
    // BK Ok
    } else {
      // wave 3
      // BK Ok
      tokens = TOKETH_PRESALE_THREE.mul(msg.value) / 1 ether;
    }
    // BK NOTE - The following line is counting the number of individual contributions, not the number of contributors
    // BK Ok
    presaleContributorCount += 1;
    
    // issue tokens
    // BK Ok
    issueTokens(msg.sender, tokens, msg.value, false); // false => not private sale
  }
  
  /* Issue tokens */
  
  // BK Ok - Private function called by 2 functions above
  function issueTokens(address _account, uint _tokens, uint _amount, bool _isPrivateSale) private {
    // register tokens purchased and Ether received
    // BK Ok
    balances[_account] = balances[_account].add(_tokens);
    // BK Ok
    tokensIssuedCrowd  = tokensIssuedCrowd.add(_tokens);
    // BK Ok
    tokensIssuedTotal  = tokensIssuedTotal.add(_tokens);
    
    // BK Ok
    if (_isPrivateSale) {
      // BK Ok
      tokensIssuedPrivate         = tokensIssuedPrivate.add(_tokens);
      // BK Ok
      etherReceivedPrivate        = etherReceivedPrivate.add(_amount);
      // BK Ok
      balancesPrivate[_account]   = balancesPrivate[_account].add(_tokens);
      // BK Ok
      balanceEthPrivate[_account] = balanceEthPrivate[_account].add(_amount);
    } else {
      // BK Ok
      etherReceivedCrowd        = etherReceivedCrowd.add(_amount);
      // BK Ok
      balancesCrowd[_account]   = balancesCrowd[_account].add(_tokens);
      // BK Ok
      balanceEthCrowd[_account] = balanceEthCrowd[_account].add(_amount);
    }
    
    // log token issuance
    // BK Next 2 Ok - Log events
    Transfer(0x0, _account, _tokens);
    TokensIssued(_account, _tokens, balances[_account], tokensIssuedCrowd, _isPrivateSale, _amount);

    // transfer Ether out
    // BK NOTE - Better to place a check `if (this.balance > 0) { ... }` around the statement below
    // BK Ok
    wallet.transfer(this.balance);

  }

  // ERC20 functions ------------------

  /* Override "transfer" */

  // BK Ok
  function transfer(address _to, uint _amount) public returns (bool success) {
    // BK Ok
    require( _to == owner || (!tokensFrozen && _to == redemptionWallet) );
    // BK Ok
    return super.transfer(_to, _amount);
  }
  
  /* Override "transferFrom" */

  // BK Ok
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    // BK Ok
    require( !tokensFrozen && _to == redemptionWallet );
    // BK Ok
    return super.transferFrom(_from, _to, _amount);
  }

}
```
