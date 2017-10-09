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
// SafeMath3
//
// Adapted from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// (no need to implement division)
//
// ----------------------------------------------------------------------------

library SafeMath3 {

  function mul(uint a, uint b) internal constant 
    returns (uint c)
  {
    c = a * b;
    assert( a == 0 || c / a == b );
  }

  function sub(uint a, uint b) internal constant
    returns (uint)
  {
    assert( b <= a );
    return a - b;
  }

  function add(uint a, uint b) internal constant
    returns (uint c)
  {
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

  event OwnershipTransferProposed(
    address indexed _from,
    address indexed _to
  );

  event OwnershipTransferred(
    address indexed _from,
    address indexed _to
  );

  // Modifier -------------------------

  modifier onlyOwner
  {
    require( msg.sender == owner );
    _;
  }

  // Functions ------------------------

  function Owned()
  {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) onlyOwner
  {
    require( _newOwner != owner );
    require( _newOwner != address(0x0) );
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership()
  {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
//
// ----------------------------------------------------------------------------

contract ERC20Interface {

  // Events ---------------------------

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint _value
  );
  
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint _value
  );

  // Functions ------------------------

  function totalSupply() constant
    returns (uint);
  
  function balanceOf(address _owner) constant 
    returns (uint balance);
  
  function transfer(address _to, uint _value)
    returns (bool success);
  
  function transferFrom(address _from, address _to, uint _value) 
    returns (bool success);
  
  function approve(address _spender, uint _value) 
    returns (bool success);
  
  function allowance(address _owner, address _spender) constant 
    returns (uint remaining);

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// note that totalSupply() is not defined here
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned {
  
  using SafeMath3 for uint;

  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  // Functions ------------------------

  /* Get the account balance for an address */

  function balanceOf(address _owner) constant 
    returns (uint balance)
  {
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  function transfer(address _to, uint _amount) 
    returns (bool success)
  {
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

  function approve(address _spender, uint _amount) 
    returns (bool success)
  {
    // before changing the approve amount for an address, its allowance
    // must be reset to 0 to mitigate the race condition described here:
    // cf https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require( _amount == 0 || allowed[msg.sender][_spender] == 0 );
      
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

  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool success) 
  {
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

  function allowance(address _owner, address _spender) constant 
    returns (uint remaining)
  {
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
  uint constant E18 = 10**18;

  /* Basic token data */

  string public constant name = "Gizer Gaming Token";
  string public constant symbol = "GZR";
  uint8  public constant decimals = 6;

  /* Wallet address - initially set to owner at deployment */
  
  address public wallet;

  /* Gizer redemption wallet - to redeem GZR tokens for Gizer gaming items */
  
  address public redemptionWallet;

  /* Token volumes */

  uint public constant TOKEN_SUPPLY_TOTAL   = 100 * E6 * E6; // 100 mm tokens
  uint public constant TOKEN_SUPPLY_TEAM    =  15 * E6 * E6; //  15 mm tokens
  uint public constant TOKEN_SUPPLY_RESERVE =  15 * E6 * E6; //  15 mm tokens
  uint public constant TOKEN_SUPPLY_CROWD   =  70 * E6 * E6; //  70 mm tokens

  /* General crowdsale parameters */  
  
  uint public constant MIN_CONTRIBUTION = E18 / 100; // 0.01 Ether
  uint public constant MAX_CONTRIBUTION = 3333 * E18; // 3,333 Ether
  uint public constant LOCKUP_PERIOD = 180 days;
  uint public constant CLAWBACK_PERIOD = 180 days;

  /* Private sale */

  uint public constant PRIVATE_SALE_MAX_ETHER = 1000 * E18; // 1,000 Ether
  
  /* Presale parameters */
  
  uint public constant DATE_PRESALE_START = 1508504400; // 20-Oct-2017 13:00 UTC
  uint public constant DATE_PRESALE_END   = 1509368400; // 30-Oct-2017 13:00 UTC
  
  uint public constant TOKETH_PRESALE_ONE   = 1150 * E6; // presale wave 1 (1-100)
  uint public constant TOKETH_PRESALE_TWO   = 1100 * E6; // presale wave 2 (101-500)
  uint public constant TOKETH_PRESALE_THREE = 1075 * E6; // presale - others
  
  uint public constant CUTOFF_PRESALE_ONE = 100; // last contributor wave 1
  uint public constant CUTOFF_PRESALE_TWO = 500; // last contributor wave 2
  
  uint public constant FUNDING_PRESALE_MIN =  333 * E18; //   333 Ether
  uint public constant FUNDING_PRESALE_MAX = 3333 * E18; // 3,333 Ether

  /* ICO parameters (ICO dates can be modified by owner after deployment) */

  uint public DATE_ICO_START = 1510754400; // 15-Nov-2017 14:00 UTC
  uint public DATE_ICO_END   = 1513346400; // 15-Dec-2017 14:00 UTC

  uint public constant TOKETH_ICO_ONE = 1050 * E6; // ICO wave 1 (1-500)
  uint public constant TOKETH_ICO_TWO = 1000 * E6; // ICO - others
  
  uint public constant CUTOFF_ICO_ONE = 500; // last contributor wave 1

  uint public constant ICO_TRIGGER = 100000 * E6; // 100,000 (for declaring ICO end)

  /* Crowdsale variables */

  uint public privateEtherReceived = 0; // private sale Ether received by Gizer
                                        // (this is not sent to the contract)

  uint public icoEtherReceived = 0; // Ether actually received by the contract
                                    // presale + ICO combined

  uint public tokensIssuedTotal = 0;
  uint public tokensIssuedCrowd = 0;
  uint public tokensIssuedTeam = 0;
  uint public tokensIssuedReserve = 0;
  
  uint public tokensIssuedPrivate = 0; // is part of tokensIssuedCrowd

  uint public lockupEndDate = DATE_ICO_END + LOCKUP_PERIOD; // changes if ICO ends early
                                                   // and resets if DATE_ICO_END changes

  bool public icoFinished = false;
  bool public tradeable = false;
  
  uint public presaleContributorCount = 0;
  uint public icoContributorCount = 0;

  /* Keep track of Ether received */
  
  mapping(address => uint) public balanceEth;
  mapping(address => uint) public balanceEthPrivate;
  
  /* Keep track of tokens issued via private sale */
  
  mapping(address => uint) public balancesPrivate;

  /* Balances subject to lockup period */
  
  mapping(address => uint) balancesLocked;

  /* Whitelist */

  address public whitelistWallet;
  mapping(address => bool) whitelist;
  
  /* Variables for pre-deployment testing */
  
  bool public constant TEST_MODE = false; // set to true for test deployment only
  uint public testTime = DATE_PRESALE_START - 1 days; // only used in test mode

  // Events ---------------------------
  
  event WalletUpdated(
    address _newWallet
  );
  
  event RedemptionWalletUpdated(
    address _newRedemptionWallet
  );

  event IcoDatesUpdated(
    uint _start,
    uint _end
  );

  event TokensIssued(
    address indexed _owner,
    uint _tokens, 
    uint _balance, 
    uint _tokensIssuedCrowd,
    bool _isPrivateSale,
    uint _amount
  );
  
  event TokensMintedTeam(
    address indexed _owner,
    uint _tokens,
    uint _balance,
    uint _tokensIssuedReserve
  );
  
  event TokensMintedReserve(
    address indexed _owner,
    uint _tokens,
    uint _balance,
    uint _tokensIssuedTeam
  );
  
  event WhitelistModify(
    address indexed _participant,
    bool _status
  );

  event WhitelistWalletChanged(
    address _newWhitelistWallet
  );

  
  // Basic Functions ------------------

  /* Initialize */

  function GizerToken() {
    wallet = msg.sender;
    redemptionWallet = wallet;
    whitelistWallet = wallet;
  }

  /* Fallback */
  
  function () payable
  {
    require( whitelist[msg.sender] == true );
    buyTokens();
  }

  // Information Functions ------------
  
  /* What time is it? */
  
  function atNow() constant
    returns (uint)
  {
    if (TEST_MODE) return testTime;
    return now;
  }

  /* Part of the balance that is locked */
  
  function lockedBalance(address _owner) constant 
    returns (uint balance)
  {
    if (atNow() > lockupEndDate) return 0;
    return balancesLocked[_owner];
  }

  /* Is an account whitelisted */

  function isWhitelisted(address _participant) constant 
    returns (bool whitelisted)
  {
    if (whitelist[_participant] == true) return true;
    return false;
  }

  /* Has the funding threshold been reached? */
  
  function icoThresholdReached() constant
    returns (bool thresholdReached)
  {
    if (icoEtherReceived >= FUNDING_PRESALE_MIN) return true;
    return false;
  }
  
  /* Balance of tokens issued via private sale */
  
  function balancePrivate(address _owner) constant 
    returns (uint tokensPrivate)
  {
    return balancesPrivate[_owner];
  }
  
  // Reclaim funds --------------------
  
  /* Reclaiming of funds by contributors in case of failed crowdsale */
  /* Will fail if account is empty after ownerClawback() */ 
  
  function reclaimFunds()
  {
    require( atNow() > DATE_ICO_END && !icoThresholdReached() );
    require( balanceEth[msg.sender] > 0 );
    
    // set balances to 0 before sending, to avoid re-entrancy
    uint amt = balanceEth[msg.sender];
    balanceEth[msg.sender] = 0;
    balances[msg.sender] = balancesPrivate[msg.sender];
    
    // send Ether balance
    msg.sender.transfer(amt);
  }
  
  // Whitelist manager functions ------

  /* Manage whitelist */

  function addToWhitelist(address _participant)
  {
    require( msg.sender == whitelistWallet );
    whitelist[_participant] = true;
    WhitelistModify(_participant, true);
  }  

  function removeFromWhitelist(address _participant)
  {
    require( msg.sender == whitelistWallet );
    whitelist[_participant] = false;
    WhitelistModify(_participant, false);
  }
  
  // Owner Functions ------------------
  
  /* Set the time (only useful in test mode) */

  function setTestTime(uint _t) onlyOwner
  {
    require( _t > testTime );
    testTime = _t;
  }

  /* Change the crowdsale wallet address */

  function setWallet(address _wallet) onlyOwner
  {
    require( _wallet != address(0x0) );
    wallet = _wallet;
    WalletUpdated(wallet);
  }

  /* Change the redemption wallet address */

  function setRedemptionWallet(address _wallet) onlyOwner
  {
    redemptionWallet = _wallet;
    RedemptionWalletUpdated(wallet);
  }
  
  /* Change the whitelist owner address */

  function setWhitelistWallet(address _wallet) onlyOwner
  {
    whitelistWallet = _wallet;
    WhitelistWalletChanged(wallet);
  }
  
  /* Change ICO dates before ICO start */
  
  function updateIcoDates(uint _start, uint _end) onlyOwner
  {
    require( atNow() < DATE_ICO_START );
    require( _start < _end );
    require( _end < DATE_PRESALE_END + 180 days ); // sanity check
    DATE_ICO_START = _start;
    DATE_ICO_END = _end;
    lockupEndDate = DATE_ICO_END + LOCKUP_PERIOD; // lockup is linked to ICO end date
    IcoDatesUpdated(_start, _end);
  }

  /* Issue tokens for ETH received during private sale */

  function privateSaleContribution(address _contributor, uint _amount) onlyOwner
  {
    require( _contributor != address(0x0) );
    require( atNow() < DATE_PRESALE_START );

    // check amount
    require( _amount >= MIN_CONTRIBUTION );
    require( privateEtherReceived.add(_amount) <= PRIVATE_SALE_MAX_ETHER );
    
    // same conditions as early presale participants
    uint tokens = TOKETH_PRESALE_ONE.mul(_amount) / E18;
    
    // issue tokens
    issueTokens(_contributor, tokens, _amount, true); // true => private sale
  }

  /* Minting of reserve tokens by owner (no lockup period) */

  function mintReserve(address _participant, uint _tokens) onlyOwner 
  {
    // available amount
    // after ICO ends, unsold tokens become available for the reserve account
    uint availableTokens = TOKEN_SUPPLY_RESERVE.sub(tokensIssuedReserve);
    if (icoFinished) {
      uint unissuedTokens = TOKEN_SUPPLY_CROWD.sub(tokensIssuedCrowd);
      availableTokens = availableTokens.add(unissuedTokens);
    }
    require( _tokens <= availableTokens );
    
    // update
    balances[_participant] = balances[_participant].add(_tokens);
    tokensIssuedReserve    = tokensIssuedReserve.add(_tokens);
    tokensIssuedTotal      = tokensIssuedTotal.add(_tokens);
    
    // log event
    Transfer(0x0, _participant, _tokens);
    TokensMintedReserve(_participant, _tokens, balances[_participant], tokensIssuedReserve);
  }

  /* Minting of team and advisors tokens by owner (with lockup period) */

  function mintTeam(address _participant, uint _tokens) onlyOwner 
  {
    // check amount
    require( _tokens <= TOKEN_SUPPLY_TEAM.sub(tokensIssuedTeam) );
    
    // these tokens are subject to lockup
    balancesLocked[_participant] = balancesLocked[_participant].add(_tokens);
    
    // update
    balances[_participant] = balances[_participant].add(_tokens);
    tokensIssuedTeam       = tokensIssuedTeam.add(_tokens);
    tokensIssuedTotal      = tokensIssuedTotal.add(_tokens);
    
    // log event
    Transfer(0x0, _participant, _tokens);
    TokensMintedTeam(_participant, _tokens, balances[_participant], tokensIssuedTeam);
  }

  /* Declare ICO finished */
  
  function declareIcoFinished() onlyOwner
  {
    require( !icoFinished );
    
    // threshold reached
    require( icoThresholdReached() );
    
    // only after ICO end date, or when cap almost reached
    require( atNow() > DATE_ICO_END || TOKEN_SUPPLY_CROWD.sub(tokensIssuedCrowd) <= ICO_TRIGGER );

    // ICO is declared finished, end of lockup period moved back if necessary
    icoFinished = true;
    if (atNow() < DATE_ICO_END) lockupEndDate = atNow() + LOCKUP_PERIOD; // only once!
  }

  /* Make tokens tradeable */
  
  function makeTradeable() onlyOwner
  {
    // the token can only be made tradeable after ICO finishes
    require( icoFinished );
    tradeable = true;
  }

  /* In case of failed ICO: */
  /* Owner clawback of remaining funds after clawback period */
  
  function ownerClawback() external onlyOwner {
    require( atNow() > DATE_ICO_END + CLAWBACK_PERIOD );
    wallet.transfer(this.balance);
  }

  /* Transfer out any accidentally sent ERC20 tokens */

  function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner 
    returns (bool success) 
  {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

  // Private functions ----------------

  /* Accept ETH during crowdsale (called by default function) */

  function buyTokens() private
  {
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
    } else if (ts > DATE_ICO_START && ts < DATE_ICO_END) {
      isIco = true;  
    }
    require( isPresale || isIco );
    
    // Presale - check the cap in ETH
    if (isPresale) {
      require( icoEtherReceived.add(msg.value) <= FUNDING_PRESALE_MAX );
      if (presaleContributorCount < CUTOFF_PRESALE_ONE) {
        tokens = TOKETH_PRESALE_ONE.mul(msg.value) / E18;
      } else if (presaleContributorCount < CUTOFF_PRESALE_TWO) {
        tokens = TOKETH_PRESALE_TWO.mul(msg.value) / E18;
      } else {
        tokens = TOKETH_PRESALE_THREE.mul(msg.value) / E18;
      }
      presaleContributorCount += 1;
    }
    
    // ICO - check the token volume cap
    if (isIco) {
      if (icoContributorCount < CUTOFF_ICO_ONE) {
        tokens = TOKETH_ICO_ONE.mul(msg.value) / E18;
      } else {
        tokens = TOKETH_ICO_TWO.mul(msg.value) / E18;
      }
      require( tokensIssuedCrowd.add(tokens) <= TOKEN_SUPPLY_CROWD );
      icoContributorCount += 1;
    }
    
    // issue tokens
    issueTokens(msg.sender, tokens, msg.value, false); // false => not private sale
  }
  
  /* Issue tokens */
  
  function issueTokens(address _contributor, uint _tokens, uint _amount, bool _isPrivateSale) private
  {
    // register tokens purchased and Ether received
    balances[_contributor] = balances[_contributor].add(_tokens);
    tokensIssuedCrowd      = tokensIssuedCrowd.add(_tokens);
    tokensIssuedTotal      = tokensIssuedTotal.add(_tokens);
    
    if (_isPrivateSale) {
      tokensIssuedPrivate             = tokensIssuedPrivate.add(_tokens);
      privateEtherReceived            = privateEtherReceived.add(_amount);
      balancesPrivate[_contributor]   = balancesPrivate[_contributor].add(_tokens);
      balanceEthPrivate[_contributor] = balanceEthPrivate[_contributor].add(_amount);
    } else {
      icoEtherReceived         = icoEtherReceived.add(msg.value);
      balanceEth[_contributor] = balanceEth[_contributor].add(msg.value);
    }
    
    // log token issuance
    Transfer(0x0, _contributor, _tokens);
    TokensIssued(_contributor, _tokens, balances[_contributor], tokensIssuedCrowd, _isPrivateSale, _amount);

    // check threshold, transfer Ether out if necessary
    if (icoThresholdReached()) {
      wallet.transfer(this.balance);
    }
  }

  // ERC20 functions ------------------

  /* Implement totalSupply() ERC20 function */
  
  function totalSupply() constant
    returns (uint)
  {
    return tokensIssuedTotal;
  }

  /* Override "transfer" (ERC20) */

  function transfer(address _to, uint _amount) 
    returns (bool success)
  {
    // cannot transfer out until tradeable, except for owner
    // or for transfers to the Gizer redemption wallet
    require( tradeable || msg.sender == owner || _to == redemptionWallet );
    
    // locked balance check
    require( balances[msg.sender].sub(_amount) >= lockedBalance(msg.sender) );

    return super.transfer(_to, _amount);
  }
  
  /* Override "transferFrom" (ERC20) */

  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool success)
  {
    // not possible until tradeable
    require( tradeable );
    
    // locked balance check
    require( balances[_from].sub(_amount) >= lockedBalance(_from) );
    
    return super.transferFrom(_from, _to, _amount);
  }

}