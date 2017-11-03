# GizerToken

Source file [../../contracts/GizerToken.sol](../../contracts/GizerToken.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.16;

// ----------------------------------------------------------------------------
//
// GZR 'Gizer Gaming' token public sale contract
//
// For details, please visit: http://www.gizer.io
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// SafeMath
//
// ----------------------------------------------------------------------------

// BK Ok
library SafeMath {

  // BK Ok - Constant function
  function mul(uint a, uint b) internal constant returns (uint c) {
    // BK Ok
    c = a * b;
    // BK Ok
    assert( a == 0 || c / a == b );
  }

  // BK Ok - Constant function
  function sub(uint a, uint b) internal constant returns (uint) {
    // BK Ok
    assert( b <= a );
    // BK Ok
    return a - b;
  }

  // BK Ok - Constant function
  function add(uint a, uint b) internal constant returns (uint c) {
    // BK Ok
    c = a + b;
    // BK Ok
    assert( c >= a );
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
  function Owned() {
    // BK Ok
    owner = msg.sender;
  }

  // BK Ok - Only current owner can execute
  function transferOwnership(address _newOwner) onlyOwner {
    // BK Ok
    require( _newOwner != owner );
    // BK Ok
    require( _newOwner != address(0x0) );
    // BK Ok - Log event
    OwnershipTransferProposed(owner, _newOwner);
    // BK Ok
    newOwner = _newOwner;
  }

  // BK Ok - Only newly proposed owner can execute
  function acceptOwnership() {
    // BK Ok
    require(msg.sender == newOwner);
    // BK Ok - Log event
    OwnershipTransferred(owner, newOwner);
    // BK Ok
    owner = newOwner;
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

  // BK Ok
  function totalSupply() constant returns (uint);
  // BK Ok
  function balanceOf(address _owner) constant returns (uint balance);
  // BK Ok
  function transfer(address _to, uint _value) returns (bool success);
  // BK Ok
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  // BK Ok
  function approve(address _spender, uint _value) returns (bool success);
  // BK Ok
  function allowance(address _owner, address _spender) constant returns (uint remaining);

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

  // BK Ok - Constant function
  function totalSupply() constant returns (uint) {
    // BK Ok
    return tokensIssuedTotal;
  }

  /* Get the account balance for an address */

  // BK Ok - Constant function
  function balanceOf(address _owner) constant returns (uint balance) {
    // BK Ok
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  // BK Ok
  function transfer(address _to, uint _amount) returns (bool success) {
    // amount sent cannot exceed balance
    // BK Ok
    require( balances[msg.sender] >= _amount );

    // update balances
    // BK Next 2 Ok
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to]        = balances[_to].add(_amount);

    // log event
    // BK Ok - Log event
    Transfer(msg.sender, _to, _amount);
    // BK Ok
    return true;
  }

  /* Allow _spender to withdraw from your account up to _amount */

  // BK Ok
  function approve(address _spender, uint _amount) returns (bool success) {
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
  function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
    // balance checks
    // BK Ok
    require( balances[_from] >= _amount );
    // BK Ok
    require( allowed[_from][msg.sender] >= _amount );

    // update balances and allowed amount
    // BK Next 3 Ok
    balances[_from]            = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to]              = balances[_to].add(_amount);

    // log event
    // BK Ok - Log event
    Transfer(_from, _to, _amount);
    // BK Ok
    return true;
  }

  /* Returns the amount of tokens approved by the owner */
  /* that can be transferred by spender */

  // BK Ok - Constant function
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    // BK Ok
    return allowed[_owner][_spender];
  }

}


// ----------------------------------------------------------------------------
//
// GZR public token sale
//
// ----------------------------------------------------------------------------

// BK Ok
contract GizerToken is ERC20Token {

  /* Utility variables */
  
  // BK Ok
  uint constant E6  = 10**6;

  /* Basic token data */

  // BK Next 3 Ok
  string public constant name     = "Gizer Gaming Token";
  string public constant symbol   = "GZR";
  uint8  public constant decimals = 6;

  /* Wallets */
  
  // BK Next 3 Ok
  address public wallet;
  address public redemptionWallet;
  address public whitelistWallet;

  /* Token volumes */

  // BK Next 4 Ok
  uint public constant TOKEN_SUPPLY_TOTAL   = 100 * E6 * E6; // 100 mm tokens
  uint public constant TOKEN_SUPPLY_TEAM    =  15 * E6 * E6; //  15 mm tokens
  uint public constant TOKEN_SUPPLY_RESERVE =  15 * E6 * E6; //  15 mm tokens
  uint public constant TOKEN_SUPPLY_CROWD   =  70 * E6 * E6; //  70 mm tokens

  /* General crowdsale parameters */  
  
  // BK Next 2 Ok
  uint public constant MIN_CONTRIBUTION = 1 ether / 100; // 0.01 Ether
  uint public constant MAX_CONTRIBUTION = 3333 ether;
  
  // BK Next 2 Ok
  uint public constant LOCKUP_PERIOD   = 180 days;
  uint public constant CLAWBACK_PERIOD = 180 days;

  /* Private sale */

  // BK Ok
  uint public constant PRIVATE_SALE_MAX_ETHER = 1000 ether;
  
  /* Presale parameters */
  
  // BK Ok - new Date(1510318800 * 1000).toUTCString() => "Fri, 10 Nov 2017 13:00:00 UTC"
  uint public constant DATE_PRESALE_START = 1510318800; // 10-Nov-2017 13:00 UTC
  // BK Ok -  new Date(1510923600 * 1000).toUTCString() => "Fri, 17 Nov 2017 13:00:00 UTC"
  uint public constant DATE_PRESALE_END   = 1510923600; // 17-Nov-2017 13:00 UTC
  
  // BK Next 3 Ok
  uint public constant TOKETH_PRESALE_ONE   = 1150 * E6; // presale wave 1 (  1-100)
  uint public constant TOKETH_PRESALE_TWO   = 1100 * E6; // presale wave 2 (101-500)
  uint public constant TOKETH_PRESALE_THREE = 1075 * E6; // presale - others
  
  // BK Next 2 Ok
  uint public constant CUTOFF_PRESALE_ONE = 100; // last contributor wave 1
  uint public constant CUTOFF_PRESALE_TWO = 500; // last contributor wave 2
  
  // BK Next 2 Ok
  uint public constant FUNDING_PRESALE_MIN =  333 ether;
  uint public constant FUNDING_PRESALE_MAX = 3333 ether;

  /* ICO parameters (ICO dates can be modified by owner after deployment) */

  // BK Ok - new Date(1511528400 * 1000).toUTCString() => "Fri, 24 Nov 2017 13:00:00 UTC"
  uint public dateIcoStart = 1511528400; // 24-Nov-2017 13:00 UTC
  // BK Ok - new Date(1513947600 * 1000).toUTCString() => "Fri, 22 Dec 2017 13:00:00 UTC"
  uint public dateIcoEnd   = 1513947600; // 22-Dec-2017 13:00 UTC

  // BK Next 2 Ok
  uint public constant TOKETH_ICO_ONE = 1050 * E6; // ICO wave 1 (1-500)
  uint public constant TOKETH_ICO_TWO = 1000 * E6; // ICO - others
  
  // BK Ok
  uint public constant CUTOFF_ICO_ONE = 500; // last contributor wave 1

  // BK Ok
  uint public constant ICO_TRIGGER = 100000 * E6; // 100,000 (for declaring ICO end)

  /* Crowdsale variables */

  // BK Next 2 Ok
  uint public etherReceivedPrivate = 0; // private sale Ether (this is not sent to the contract)
  uint public etherReceivedCrowd   = 0; // Ether actually received by the contract (presale + ICO)

  // BK Next 4 Ok
  uint public tokensIssuedCrowd   = 0;
  uint public tokensIssuedTeam    = 0;
  uint public tokensIssuedReserve = 0;
  uint public tokensIssuedPrivate = 0; // is part of tokensIssuedCrowd

  // BK Ok
  uint public lockupEndDate = dateIcoEnd + LOCKUP_PERIOD; // changes if ICO ends early
                                                          // resets if dateIcoEnd changes

  // BK Next 2 Ok
  bool public icoFinished = false;
  bool public tradeable = false;
  
  // BK Next 2 Ok
  uint public presaleContributorCount = 0;
  uint public icoContributorCount = 0;

  /* Mappings */
  
  // BK Ok
  mapping(address => bool) public whitelist;         // only addresses on whitelist can contribute during crowdsale

  // BK Next 2 Ok
  mapping(address => uint) public balanceEthCrowd;   // Ether contributed during crowdsale (excluding private sale)
  mapping(address => uint) public balanceEthPrivate; // Ether contributed during private sale (not sent to contract)

  // BK Next 2 Ok
  mapping(address => uint) public balancesCrowd;     // tokens received for Crowdsale Ether contributions
  mapping(address => uint) public balancesPrivate;   // tokens received for private sale Ether contributions

  // BK Ok
  mapping(address => uint) public balancesLocked;    // token balances subject to lockup - minted via mintTeam()

  // Events ---------------------------
  
  // BK Next 8 Ok - Events
  event WalletUpdated(address _newWallet);
  event RedemptionWalletUpdated(address _newRedemptionWallet);
  event WhitelistWalletUpdated(address _newWhitelistWallet);
  event IcoDatesUpdated(uint _start, uint _end);
  event TokensIssued(address indexed _owner, uint _tokens, uint _balance, uint _tokensIssuedCrowd, bool indexed _isPrivateSale, uint _amount);
  event TokensMintedTeam(address indexed _owner, uint _tokens, uint _balance, uint _tokensIssuedReserve);
  event TokensMintedReserve(address indexed _owner, uint _tokens, uint _balance, uint _tokensIssuedTeam);
  event WhitelistUpdated(address indexed _participant, bool _status);
  
  // Basic Functions ------------------

  /* Initialize */

  // BK Ok - Constructor
  function GizerToken() {
    // BK Ok
    require( TOKEN_SUPPLY_TEAM + TOKEN_SUPPLY_RESERVE + TOKEN_SUPPLY_CROWD == TOKEN_SUPPLY_TOTAL );
    // BK Ok
    wallet = owner;
    // BK Ok
    redemptionWallet = owner;
    // BK Ok
    whitelistWallet = owner;
  }

  /* Fallback */
  
  // BK Ok - Default function, payable
  function () payable {
    // BK Ok
    require( whitelist[msg.sender] == true );
    // BK Ok
    buyTokens();
  }

  // Information Functions ------------
  
  /* What time is it? */
  
  // BK Ok
  function atNow() constant returns (uint) {
    // BK Ok
    return now;
  }

  /* Part of the balance that is locked */
  
  // BK Ok - Constant function
  function lockedBalance(address _owner) constant returns (uint balance) {
    // BK Ok
    if (atNow() > lockupEndDate) return 0;
    // BK Ok
    return balancesLocked[_owner];
  }

  /* Has the funding threshold been reached? */
  
  // BK Ok - Constant function
  function icoThresholdReached() constant returns (bool thresholdReached) {
    // BK Ok
    if (etherReceivedCrowd >= FUNDING_PRESALE_MIN) return true;
    // BK Ok
    return false;
  }
  
  // Whitelist manager functions ------

  /* Manage whitelist */

  // BK Ok - Can only be executed by whitelistWallet or owner
  function addToWhitelist(address _participant) {
    // BK Ok
    require( msg.sender == whitelistWallet || msg.sender == owner );
    // BK Ok
    whitelist[_participant] = true;
    // BK Ok - Log event
    WhitelistUpdated(_participant, true);
  }  

  // BK Ok - Can only be executed by whitelistWallet or owner
  function removeFromWhitelist(address _participant) {
    // BK Ok
    require( msg.sender == whitelistWallet || msg.sender == owner );
    // BK Ok
    whitelist[_participant] = false;
    // BK Ok - Lov event
    WhitelistUpdated(_participant, false);
  }
  
  // Owner Functions ------------------
  
  /* Change the crowdsale wallet address */

  // BK Ok - Only owner can execute
  function setWallet(address _wallet) onlyOwner {
    // BK Ok
    require( _wallet != address(0x0) );
    // BK Ok
    wallet = _wallet;
    // BK Ok
    WalletUpdated(_wallet);
  }

  /* Change the redemption wallet address */

  // BK Ok - Only owner can execute
  function setRedemptionWallet(address _wallet) onlyOwner {
    // BK Ok
    redemptionWallet = _wallet;
    // BK Ok
    RedemptionWalletUpdated(_wallet);
  }
  
  /* Change the whitelist owner address */

  // BK Ok - Only owner can execute
  function setWhitelistWallet(address _wallet) onlyOwner {
    // BK Ok
    whitelistWallet = _wallet;
    // BK Ok - Log event
    WhitelistWalletUpdated(_wallet);
  }
  
  /* Change ICO dates before ICO start */
  
  // BK Ok - Only owner can execute
  function updateIcoDates(uint _start, uint _end) onlyOwner {
    // BK Ok
    require( atNow() < dateIcoStart );
    // BK Ok
    require( atNow() < _start && _start < _end );
    // BK Ok
    require( _end < DATE_PRESALE_END + 180 days ); // sanity check
    
    // update
    // BK Ok
    dateIcoStart = _start;
    // BK Ok
    dateIcoEnd = _end;
    // BK Ok
    lockupEndDate = dateIcoEnd.add(LOCKUP_PERIOD);
    
    //log
    // BK Ok - Log event
    IcoDatesUpdated(_start, _end);
  }

  /* Issue tokens for ETH received during private sale */

  // BK Ok - Only owner can execute
  function privateSaleContribution(address _account, uint _amount) onlyOwner {
    // BK Ok
    require( _account != address(0x0) );
    // BK Ok
    require( atNow() < DATE_PRESALE_START );

    // check amount
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

  /* Minting of reserve tokens by owner (no lockup period) */

  // BK Ok - Only owner can execute
  function mintReserve(address _account, uint _tokens) onlyOwner {
    // available amount
    // after ICO ends, unsold tokens become available for the reserve account
    // BK Ok
    uint availableTokens = TOKEN_SUPPLY_RESERVE.sub(tokensIssuedReserve);
    // BK Ok
    if (icoFinished) {
      // BK Ok
      uint unissuedTokens = TOKEN_SUPPLY_CROWD.sub(tokensIssuedCrowd);
      // BK Ok
      availableTokens = availableTokens.add(unissuedTokens);
    }
    // BK Ok
    require( _tokens <= availableTokens );
    
    // update
    // BK Next 3 Ok
    balances[_account]  = balances[_account].add(_tokens);
    tokensIssuedReserve = tokensIssuedReserve.add(_tokens);
    tokensIssuedTotal   = tokensIssuedTotal.add(_tokens);
    
    // log event
    // BK Next 2 Ok - Log events
    Transfer(0x0, _account, _tokens);
    TokensMintedReserve(_account, _tokens, balances[_account], tokensIssuedReserve);
  }

  /* Minting of team and advisors tokens by owner (with lockup period) */

  // BK Ok - Only owner can execute
  function mintTeam(address _account, uint _tokens) onlyOwner {
    // check amount
    // BK Ok
    require( _tokens <= TOKEN_SUPPLY_TEAM.sub(tokensIssuedTeam) );
    
    // these tokens are subject to lockup
    // BK Ok
    balancesLocked[_account] = balancesLocked[_account].add(_tokens);
    
    // update
    // BK Next 3 Ok
    balances[_account] = balances[_account].add(_tokens);
    tokensIssuedTeam   = tokensIssuedTeam.add(_tokens);
    tokensIssuedTotal  = tokensIssuedTotal.add(_tokens);
    
    // log event
    // BK Next 2 Ok - Log events
    Transfer(0x0, _account, _tokens);
    TokensMintedTeam(_account, _tokens, balances[_account], tokensIssuedTeam);
  }

  /* Declare ICO finished */
  
  // BK Ok - Only owner can execute
  function declareIcoFinished() onlyOwner {
    // BK Ok
    require( !icoFinished );
    
    // threshold reached
    // BK Ok
    require( icoThresholdReached() );
    
    // only after ICO end date, or when cap almost reached
    // BK Ok
    require( atNow() > dateIcoEnd || TOKEN_SUPPLY_CROWD.sub(tokensIssuedCrowd) <= ICO_TRIGGER );

    // ICO is declared finished, end of lockup period moved back if necessary
    // BK Ok
    icoFinished = true;
    // BK Ok
    if (atNow() < dateIcoEnd) lockupEndDate = atNow() + LOCKUP_PERIOD; // only once!
  }

  /* Make tokens tradeable */
  
  // BK Ok - Only owner can execute
  function makeTradeable() onlyOwner {
    // the token can only be made tradeable after ICO finishes
    // BK Ok
    require( icoFinished );
    // BK Ok
    tradeable = true;
  }

  /* In case of failed ICO: */
  /* Owner clawback of remaining funds after clawback period */
  
  // BK Ok - Only owner can execute
  function ownerClawback() external onlyOwner {
    // BK Ok
    require( atNow() > dateIcoEnd + CLAWBACK_PERIOD );
    // BK Ok
    wallet.transfer(this.balance);
  }

  /* Transfer out any accidentally sent ERC20 tokens */

  // BK Ok - Only owner can execute
  function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner returns (bool success) {
      // BK Ok
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

  // External functions ---------------
  
  /* Reclaiming of funds by contributors in case of failed crowdsale */
  /* Note that there would have been no token transfers in that case */
  /* Will fail if account is empty after ownerClawback() */ 
  
  // BK Ok - Only contributors can execute
  function reclaimFunds() external {
    // BK Ok
    require( atNow() > dateIcoEnd && !icoThresholdReached() );
    // BK Ok
    require( balanceEthCrowd[msg.sender] > 0 );
    
    // set balances to 0 before sending, to avoid re-entrancy
    // BK Ok
    uint amt = balanceEthCrowd[msg.sender];
    // BK Ok
    balanceEthCrowd[msg.sender] = 0;
    
    // send Ether balance
    // BK Ok
    msg.sender.transfer(amt);
    
    // destruction of crowdsale tokens received
    // BK Next 4 Ok
    uint tokensDestroyed = balancesCrowd[msg.sender];
    balancesCrowd[msg.sender] = 0;
    balances[msg.sender] = balances[msg.sender].sub(tokensDestroyed);
    tokensIssuedTotal = tokensIssuedTotal.sub(tokensDestroyed);
    
    // log
    // BK Ok - Log event
    Transfer(msg.sender, 0x0, tokensDestroyed);
  }

  // Private functions ----------------

  /* Accept ETH during crowdsale (called by default function) */

  // BK Ok
  function buyTokens() private {
    // BK Ok
    uint ts = atNow();
    // BK Ok
    bool isPresale = false;
    // BK Ok
    bool isIco = false;
    // BK Ok
    uint tokens = 0;

    // basic checks
    // BK Ok
    require( !icoFinished );
    // BK Ok
    require( msg.value >= MIN_CONTRIBUTION && msg.value <= MAX_CONTRIBUTION );

    // check dates for presale or ICO
    // BK Ok
    if (ts > DATE_PRESALE_START && ts < DATE_PRESALE_END) {
      // BK Ok
      isPresale = true;  
    // BK Ok
    } else if (ts > dateIcoStart && ts < dateIcoEnd) {
      // BK Ok
      isIco = true;  
    }
    // BK Ok
    require( isPresale || isIco );
    
    // Presale - check the cap in ETH
    // BK Ok
    if (isPresale) {
      // BK Ok
      require( etherReceivedCrowd.add(msg.value) <= FUNDING_PRESALE_MAX );
      // BK Ok
      if (presaleContributorCount < CUTOFF_PRESALE_ONE) {
        // BK Ok
        tokens = TOKETH_PRESALE_ONE.mul(msg.value) / 1 ether;
      // BK Ok
      } else if (presaleContributorCount < CUTOFF_PRESALE_TWO) {
        // BK Ok
        tokens = TOKETH_PRESALE_TWO.mul(msg.value) / 1 ether;
      // BK Ok
      } else {
        // BK Ok
        tokens = TOKETH_PRESALE_THREE.mul(msg.value) / 1 ether;
      }
      // BK Ok
      presaleContributorCount += 1;
    }
    
    // ICO - check the token volume cap
    // BK Ok
    if (isIco) {
      // BK Ok
      if (icoContributorCount < CUTOFF_ICO_ONE) {
        // BK Ok
        tokens = TOKETH_ICO_ONE.mul(msg.value) / 1 ether;
      // BK Ok
      } else {
        // BK Ok
        tokens = TOKETH_ICO_TWO.mul(msg.value) / 1 ether;
      }
      // BK Ok
      require( tokensIssuedCrowd.add(tokens) <= TOKEN_SUPPLY_CROWD );
      // BK Ok
      icoContributorCount += 1;
    }
    
    // issue tokens
    // BK Ok
    issueTokens(msg.sender, tokens, msg.value, false); // false => not private sale
  }
  
  /* Issue tokens */
  
  // BK Ok - Private
  function issueTokens(address _account, uint _tokens, uint _amount, bool _isPrivateSale) private {
    // register tokens purchased and Ether received
    // BK Next 3 Ok
    balances[_account] = balances[_account].add(_tokens);
    tokensIssuedCrowd  = tokensIssuedCrowd.add(_tokens);
    tokensIssuedTotal  = tokensIssuedTotal.add(_tokens);
    
    // BK Ok
    if (_isPrivateSale) {
      // BK Next 3 Ok
      tokensIssuedPrivate         = tokensIssuedPrivate.add(_tokens);
      etherReceivedPrivate        = etherReceivedPrivate.add(_amount);
      balancesPrivate[_account]   = balancesPrivate[_account].add(_tokens);
      balanceEthPrivate[_account] = balanceEthPrivate[_account].add(_amount);
    // BK Ok
    } else {
      // BK Next 3 Ok
      etherReceivedCrowd        = etherReceivedCrowd.add(_amount);
      balancesCrowd[_account]   = balancesCrowd[_account].add(_tokens);
      balanceEthCrowd[_account] = balanceEthCrowd[_account].add(_amount);
    }
    
    // log token issuance
    // BK Next 2 Ok - Log event
    Transfer(0x0, _account, _tokens);
    TokensIssued(_account, _tokens, balances[_account], tokensIssuedCrowd, _isPrivateSale, _amount);

    // check threshold, transfer Ether out if necessary
    // BK Ok
    if (icoThresholdReached()) {
      // BK Ok
      wallet.transfer(this.balance);
    }
  }

  // ERC20 functions ------------------

  /* Override "transfer" */

  // BK Ok
  function transfer(address _to, uint _amount) returns (bool success) {
    // BK Ok
    require( tradeable );
    // BK Ok
    require( balances[msg.sender].sub(_amount) >= lockedBalance(msg.sender) );
    // BK Ok
    return super.transfer(_to, _amount);
  }
  
  /* Override "transferFrom" */

  // BK Ok
  function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
    // BK Ok
    require( tradeable );
    // BK Ok
    require( balances[_from].sub(_amount) >= lockedBalance(_from) );
    // BK Ok
    return super.transferFrom(_from, _to, _amount);
  }

  // Bulk token transfer function -----

  /* Multiple token transfers from one address to save gas */

  // BK Ok
  function transferMultiple(address[] _addresses, uint[] _amounts) external {
    // BK Ok
    require( tradeable );
    // BK Ok
    require( _addresses.length == _amounts.length );
    // BK Ok
    for (uint i = 0; i < _addresses.length; i++) {
      // BK Ok
      require( balances[msg.sender].sub(_amounts[i]) >= lockedBalance(msg.sender) );
      // BK Ok
      super.transfer(_addresses[i], _amounts[i]);
    }
  }  
  
}
```
