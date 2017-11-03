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

library SafeMath {

  function mul(uint a, uint b) internal constant returns (uint c) {
    c = a * b;
    assert( a == 0 || c / a == b );
  }

  function sub(uint a, uint b) internal constant returns (uint) {
    assert( b <= a );
    return a - b;
  }

  function add(uint a, uint b) internal constant returns (uint c) {
    c = a + b;
    assert( c >= a );
  }

}


// ----------------------------------------------------------------------------
//
// Owned contract
//
// ----------------------------------------------------------------------------

contract Owned {

  address public owner;
  address public newOwner;

  // Events ---------------------------

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);

  // Modifier -------------------------

  modifier onlyOwner {
    require( msg.sender == owner );
    _;
  }

  // Functions ------------------------

  function Owned() {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) onlyOwner {
    require( _newOwner != owner );
    require( _newOwner != address(0x0) );
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
// ----------------------------------------------------------------------------

contract ERC20Interface {

  // Events ---------------------------

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  // Functions ------------------------

  function totalSupply() constant returns (uint);
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint remaining);

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned {
  
  using SafeMath for uint;

  uint public tokensIssuedTotal = 0;
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  // Functions ------------------------

  /* Total token supply */

  function totalSupply() constant returns (uint) {
    return tokensIssuedTotal;
  }

  /* Get the account balance for an address */

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  function transfer(address _to, uint _amount) returns (bool success) {
    // amount sent cannot exceed balance
    require( balances[msg.sender] >= _amount );

    // update balances
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to]        = balances[_to].add(_amount);

    // log event
    Transfer(msg.sender, _to, _amount);
    return true;
  }

  /* Allow _spender to withdraw from your account up to _amount */

  function approve(address _spender, uint _amount) returns (bool success) {
    // approval amount cannot exceed the balance
    require ( balances[msg.sender] >= _amount );
      
    // update allowed amount
    allowed[msg.sender][_spender] = _amount;
    
    // log event
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  /* Spender of tokens transfers tokens from the owner's balance */
  /* Must be pre-approved by owner */

  function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
    // balance checks
    require( balances[_from] >= _amount );
    require( allowed[_from][msg.sender] >= _amount );

    // update balances and allowed amount
    balances[_from]            = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to]              = balances[_to].add(_amount);

    // log event
    Transfer(_from, _to, _amount);
    return true;
  }

  /* Returns the amount of tokens approved by the owner */
  /* that can be transferred by spender */

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


// ----------------------------------------------------------------------------
//
// GZR public token sale
//
// ----------------------------------------------------------------------------

contract GizerToken is ERC20Token {

  /* Utility variables */
  
  uint constant E6  = 10**6;

  /* Basic token data */

  string public constant name     = "Gizer Gaming Token";
  string public constant symbol   = "GZR";
  uint8  public constant decimals = 6;

  /* Wallets */
  
  address public wallet;
  address public redemptionWallet;
  address public whitelistWallet;

  /* Token volumes */

  uint public constant TOKEN_SUPPLY_TOTAL   = 100 * E6 * E6; // 100 mm tokens
  uint public constant TOKEN_SUPPLY_TEAM    =  15 * E6 * E6; //  15 mm tokens
  uint public constant TOKEN_SUPPLY_RESERVE =  15 * E6 * E6; //  15 mm tokens
  uint public constant TOKEN_SUPPLY_CROWD   =  70 * E6 * E6; //  70 mm tokens

  /* General crowdsale parameters */  
  
  uint public constant MIN_CONTRIBUTION = 1 ether / 100; // 0.01 Ether
  uint public constant MAX_CONTRIBUTION = 3333 ether;
  
  uint public constant LOCKUP_PERIOD   = 180 days;
  uint public constant CLAWBACK_PERIOD = 180 days;

  /* Private sale */

  uint public constant PRIVATE_SALE_MAX_ETHER = 1000 ether;
  
  /* Presale parameters */
  
  uint public constant DATE_PRESALE_START = 1510318800; // 10-Nov-2017 13:00 UTC
  uint public constant DATE_PRESALE_END   = 1510923600; // 17-Nov-2017 13:00 UTC
  
  uint public constant TOKETH_PRESALE_ONE   = 1150 * E6; // presale wave 1 (  1-100)
  uint public constant TOKETH_PRESALE_TWO   = 1100 * E6; // presale wave 2 (101-500)
  uint public constant TOKETH_PRESALE_THREE = 1075 * E6; // presale - others
  
  uint public constant CUTOFF_PRESALE_ONE = 100; // last contributor wave 1
  uint public constant CUTOFF_PRESALE_TWO = 500; // last contributor wave 2
  
  uint public constant FUNDING_PRESALE_MIN =  333 ether;
  uint public constant FUNDING_PRESALE_MAX = 3333 ether;

  /* ICO parameters (ICO dates can be modified by owner after deployment) */

  uint public dateIcoStart = 1511528400; // 24-Nov-2017 13:00 UTC
  uint public dateIcoEnd   = 1513947600; // 22-Dec-2017 13:00 UTC

  uint public constant TOKETH_ICO_ONE = 1050 * E6; // ICO wave 1 (1-500)
  uint public constant TOKETH_ICO_TWO = 1000 * E6; // ICO - others
  
  uint public constant CUTOFF_ICO_ONE = 500; // last contributor wave 1

  uint public constant ICO_TRIGGER = 100000 * E6; // 100,000 (for declaring ICO end)

  /* Crowdsale variables */

  uint public etherReceivedPrivate = 0; // private sale Ether (this is not sent to the contract)
  uint public etherReceivedCrowd   = 0; // Ether actually received by the contract (presale + ICO)

  uint public tokensIssuedCrowd   = 0;
  uint public tokensIssuedTeam    = 0;
  uint public tokensIssuedReserve = 0;
  uint public tokensIssuedPrivate = 0; // is part of tokensIssuedCrowd

  uint public lockupEndDate = dateIcoEnd + LOCKUP_PERIOD; // changes if ICO ends early
                                                          // resets if dateIcoEnd changes

  bool public icoFinished = false;
  bool public tradeable = false;
  
  uint public presaleContributorCount = 0;
  uint public icoContributorCount = 0;

  /* Mappings */
  
  mapping(address => bool) public whitelist;         // only addresses on whitelist can contribute during crowdsale

  mapping(address => uint) public balanceEthCrowd;   // Ether contributed during crowdsale (excluding private sale)
  mapping(address => uint) public balanceEthPrivate; // Ether contributed during private sale (not sent to contract)

  mapping(address => uint) public balancesCrowd;     // tokens received for Crowdsale Ether contributions
  mapping(address => uint) public balancesPrivate;   // tokens received for private sale Ether contributions

  mapping(address => uint) public balancesLocked;    // token balances subject to lockup - minted via mintTeam()

  // Events ---------------------------
  
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

  function GizerToken() {
    require( TOKEN_SUPPLY_TEAM + TOKEN_SUPPLY_RESERVE + TOKEN_SUPPLY_CROWD == TOKEN_SUPPLY_TOTAL );
    wallet = owner;
    redemptionWallet = owner;
    whitelistWallet = owner;
  }

  /* Fallback */
  
  function () payable {
    require( whitelist[msg.sender] == true );
    buyTokens();
  }

  // Information Functions ------------
  
  /* What time is it? */
  
  function atNow() constant returns (uint) {
    return now;
  }

  /* Part of the balance that is locked */
  
  function lockedBalance(address _owner) constant returns (uint balance) {
    if (atNow() > lockupEndDate) return 0;
    return balancesLocked[_owner];
  }

  /* Has the funding threshold been reached? */
  
  function icoThresholdReached() constant returns (bool thresholdReached) {
    if (etherReceivedCrowd >= FUNDING_PRESALE_MIN) return true;
    return false;
  }
  
  // Whitelist manager functions ------

  /* Manage whitelist */

  function addToWhitelist(address _participant) {
    require( msg.sender == whitelistWallet || msg.sender == owner );
    whitelist[_participant] = true;
    WhitelistUpdated(_participant, true);
  }  

  function removeFromWhitelist(address _participant) {
    require( msg.sender == whitelistWallet || msg.sender == owner );
    whitelist[_participant] = false;
    WhitelistUpdated(_participant, false);
  }
  
  // Owner Functions ------------------
  
  /* Change the crowdsale wallet address */

  function setWallet(address _wallet) onlyOwner {
    require( _wallet != address(0x0) );
    wallet = _wallet;
    WalletUpdated(_wallet);
  }

  /* Change the redemption wallet address */

  function setRedemptionWallet(address _wallet) onlyOwner {
    redemptionWallet = _wallet;
    RedemptionWalletUpdated(_wallet);
  }
  
  /* Change the whitelist owner address */

  function setWhitelistWallet(address _wallet) onlyOwner {
    whitelistWallet = _wallet;
    WhitelistWalletUpdated(_wallet);
  }
  
  /* Change ICO dates before ICO start */
  
  function updateIcoDates(uint _start, uint _end) onlyOwner {
    require( atNow() < dateIcoStart );
    require( atNow() < _start && _start < _end );
    require( _end < DATE_PRESALE_END + 180 days ); // sanity check
    
    // update
    dateIcoStart = _start;
    dateIcoEnd = _end;
    lockupEndDate = dateIcoEnd.add(LOCKUP_PERIOD);
    
    //log
    IcoDatesUpdated(_start, _end);
  }

  /* Issue tokens for ETH received during private sale */

  function privateSaleContribution(address _account, uint _amount) onlyOwner {
    require( _account != address(0x0) );
    require( atNow() < DATE_PRESALE_START );

    // check amount
    require( _amount >= MIN_CONTRIBUTION );
    require( etherReceivedPrivate.add(_amount) <= PRIVATE_SALE_MAX_ETHER );
    
    // same conditions as early presale participants
    uint tokens = TOKETH_PRESALE_ONE.mul(_amount) / 1 ether;
    
    // issue tokens
    issueTokens(_account, tokens, _amount, true); // true => private sale
  }

  /* Minting of reserve tokens by owner (no lockup period) */

  function mintReserve(address _account, uint _tokens) onlyOwner {
    // available amount
    // after ICO ends, unsold tokens become available for the reserve account
    uint availableTokens = TOKEN_SUPPLY_RESERVE.sub(tokensIssuedReserve);
    if (icoFinished) {
      uint unissuedTokens = TOKEN_SUPPLY_CROWD.sub(tokensIssuedCrowd);
      availableTokens = availableTokens.add(unissuedTokens);
    }
    require( _tokens <= availableTokens );
    
    // update
    balances[_account]  = balances[_account].add(_tokens);
    tokensIssuedReserve = tokensIssuedReserve.add(_tokens);
    tokensIssuedTotal   = tokensIssuedTotal.add(_tokens);
    
    // log event
    Transfer(0x0, _account, _tokens);
    TokensMintedReserve(_account, _tokens, balances[_account], tokensIssuedReserve);
  }

  /* Minting of team and advisors tokens by owner (with lockup period) */

  function mintTeam(address _account, uint _tokens) onlyOwner {
    // check amount
    require( _tokens <= TOKEN_SUPPLY_TEAM.sub(tokensIssuedTeam) );
    
    // these tokens are subject to lockup
    balancesLocked[_account] = balancesLocked[_account].add(_tokens);
    
    // update
    balances[_account] = balances[_account].add(_tokens);
    tokensIssuedTeam   = tokensIssuedTeam.add(_tokens);
    tokensIssuedTotal  = tokensIssuedTotal.add(_tokens);
    
    // log event
    Transfer(0x0, _account, _tokens);
    TokensMintedTeam(_account, _tokens, balances[_account], tokensIssuedTeam);
  }

  /* Declare ICO finished */
  
  function declareIcoFinished() onlyOwner {
    require( !icoFinished );
    
    // threshold reached
    require( icoThresholdReached() );
    
    // only after ICO end date, or when cap almost reached
    require( atNow() > dateIcoEnd || TOKEN_SUPPLY_CROWD.sub(tokensIssuedCrowd) <= ICO_TRIGGER );

    // ICO is declared finished, end of lockup period moved back if necessary
    icoFinished = true;
    if (atNow() < dateIcoEnd) lockupEndDate = atNow() + LOCKUP_PERIOD; // only once!
  }

  /* Make tokens tradeable */
  
  function makeTradeable() onlyOwner {
    // the token can only be made tradeable after ICO finishes
    require( icoFinished );
    tradeable = true;
  }

  /* In case of failed ICO: */
  /* Owner clawback of remaining funds after clawback period */
  
  function ownerClawback() external onlyOwner {
    require( atNow() > dateIcoEnd + CLAWBACK_PERIOD );
    wallet.transfer(this.balance);
  }

  /* Transfer out any accidentally sent ERC20 tokens */

  function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

  // External functions ---------------
  
  /* Reclaiming of funds by contributors in case of failed crowdsale */
  /* Note that there would have been no token transfers in that case */
  /* Will fail if account is empty after ownerClawback() */ 
  
  function reclaimFunds() external {
    require( atNow() > dateIcoEnd && !icoThresholdReached() );
    require( balanceEthCrowd[msg.sender] > 0 );
    
    // set balances to 0 before sending, to avoid re-entrancy
    uint amt = balanceEthCrowd[msg.sender];
    balanceEthCrowd[msg.sender] = 0;
    
    // send Ether balance
    msg.sender.transfer(amt);
    
    // destruction of crowdsale tokens received
    uint tokensDestroyed = balancesCrowd[msg.sender];
    balancesCrowd[msg.sender] = 0;
    balances[msg.sender] = balances[msg.sender].sub(tokensDestroyed);
    tokensIssuedTotal = tokensIssuedTotal.sub(tokensDestroyed);
    
    // log
    Transfer(msg.sender, 0x0, tokensDestroyed);
  }

  // Private functions ----------------

  /* Accept ETH during crowdsale (called by default function) */

  function buyTokens() private {
    uint ts = atNow();
    bool isPresale = false;
    bool isIco = false;
    uint tokens = 0;

    // basic checks
    require( !icoFinished );
    require( msg.value >= MIN_CONTRIBUTION && msg.value <= MAX_CONTRIBUTION );

    // check dates for presale or ICO
    if (ts > DATE_PRESALE_START && ts < DATE_PRESALE_END) {
      isPresale = true;  
    } else if (ts > dateIcoStart && ts < dateIcoEnd) {
      isIco = true;  
    }
    require( isPresale || isIco );
    
    // Presale - check the cap in ETH
    if (isPresale) {
      require( etherReceivedCrowd.add(msg.value) <= FUNDING_PRESALE_MAX );
      if (presaleContributorCount < CUTOFF_PRESALE_ONE) {
        tokens = TOKETH_PRESALE_ONE.mul(msg.value) / 1 ether;
      } else if (presaleContributorCount < CUTOFF_PRESALE_TWO) {
        tokens = TOKETH_PRESALE_TWO.mul(msg.value) / 1 ether;
      } else {
        tokens = TOKETH_PRESALE_THREE.mul(msg.value) / 1 ether;
      }
      presaleContributorCount += 1;
    }
    
    // ICO - check the token volume cap
    if (isIco) {
      if (icoContributorCount < CUTOFF_ICO_ONE) {
        tokens = TOKETH_ICO_ONE.mul(msg.value) / 1 ether;
      } else {
        tokens = TOKETH_ICO_TWO.mul(msg.value) / 1 ether;
      }
      require( tokensIssuedCrowd.add(tokens) <= TOKEN_SUPPLY_CROWD );
      icoContributorCount += 1;
    }
    
    // issue tokens
    issueTokens(msg.sender, tokens, msg.value, false); // false => not private sale
  }
  
  /* Issue tokens */
  
  function issueTokens(address _account, uint _tokens, uint _amount, bool _isPrivateSale) private {
    // register tokens purchased and Ether received
    balances[_account] = balances[_account].add(_tokens);
    tokensIssuedCrowd  = tokensIssuedCrowd.add(_tokens);
    tokensIssuedTotal  = tokensIssuedTotal.add(_tokens);
    
    if (_isPrivateSale) {
      tokensIssuedPrivate         = tokensIssuedPrivate.add(_tokens);
      etherReceivedPrivate        = etherReceivedPrivate.add(_amount);
      balancesPrivate[_account]   = balancesPrivate[_account].add(_tokens);
      balanceEthPrivate[_account] = balanceEthPrivate[_account].add(_amount);
    } else {
      etherReceivedCrowd        = etherReceivedCrowd.add(_amount);
      balancesCrowd[_account]   = balancesCrowd[_account].add(_tokens);
      balanceEthCrowd[_account] = balanceEthCrowd[_account].add(_amount);
    }
    
    // log token issuance
    Transfer(0x0, _account, _tokens);
    TokensIssued(_account, _tokens, balances[_account], tokensIssuedCrowd, _isPrivateSale, _amount);

    // check threshold, transfer Ether out if necessary
    if (icoThresholdReached()) {
      wallet.transfer(this.balance);
    }
  }

  // ERC20 functions ------------------

  /* Override "transfer" */

  function transfer(address _to, uint _amount) returns (bool success) {
    require( tradeable );
    require( balances[msg.sender].sub(_amount) >= lockedBalance(msg.sender) );
    return super.transfer(_to, _amount);
  }
  
  /* Override "transferFrom" */

  function transferFrom(address _from, address _to, uint _amount) returns (bool success) {
    require( tradeable );
    require( balances[_from].sub(_amount) >= lockedBalance(_from) );
    return super.transferFrom(_from, _to, _amount);
  }

  // Bulk token transfer function -----

  /* Multiple token transfers from one address to save gas */

  function transferMultiple(address[] _addresses, uint[] _amounts) external {
    require( tradeable );
    require( _addresses.length == _amounts.length );
    for (uint i = 0; i < _addresses.length; i++) {
      require( balances[msg.sender].sub(_amounts[i]) >= lockedBalance(msg.sender) );
      super.transfer(_addresses[i], _amounts[i]);
    }
  }  
  
}