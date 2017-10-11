# GizerTokenSale

Source file [../../contracts/GizerTokenSale.sol](../../contracts/GizerTokenSale.sol).

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
// SafeMath3
//
// Adapted from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// (no need to implement division)
//
// ----------------------------------------------------------------------------

// BK Ok
library SafeMath3 {

  // BK Ok
  function mul(uint a, uint b) internal constant 
    returns (uint c)
  {
    // BK Ok
    c = a * b;
    // BK Ok
    assert( a == 0 || c / a == b );
  }

  // BK Ok
  function sub(uint a, uint b) internal constant
    returns (uint)
  {
    // BK Ok
    assert( b <= a );
    // BK Ok
    return a - b;
  }

  // BK Ok
  function add(uint a, uint b) internal constant
    returns (uint c)
  {
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

  // BK Ok - Event
  event OwnershipTransferProposed(
    address indexed _from,
    address indexed _to
  );

  // BK Ok - Event
  event OwnershipTransferred(
    address indexed _from,
    address indexed _to
  );

  // Modifier -------------------------

  // BK Ok
  modifier onlyOwner
  {
    // BK Ok
    require( msg.sender == owner );
    // BK Ok
    _;
  }

  // Functions ------------------------

  // BK Ok - Constructor
  function Owned()
  {
    // BK Ok
    owner = msg.sender;
  }

  // BK Ok - Only owner can execute
  function transferOwnership(address _newOwner) onlyOwner
  {
    // BK Ok
    require( _newOwner != owner );
    // BK Ok
    require( _newOwner != address(0x0) );
    // BK Ok - Log event
    OwnershipTransferProposed(owner, _newOwner);
    // BK Ok
    newOwner = _newOwner;
  }

  // BK Ok - Only newOwner can execute
  function acceptOwnership()
  {
    // BK Ok
    require(msg.sender == newOwner);
    // BK Ok
    OwnershipTransferred(owner, newOwner);
    // BK Ok
    owner = newOwner;
  }

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
//
// ----------------------------------------------------------------------------

// BK Ok
contract ERC20Interface {

  // Events ---------------------------

  // BK Ok - Event
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint _value
  );
  
  // BK Ok - Event
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint _value
  );

  // Functions ------------------------

  // BK Ok - Constant function
  function totalSupply() constant
    returns (uint);
  
  // BK Ok - Constant function
  function balanceOf(address _owner) constant 
    returns (uint balance);
  
  // BK Ok
  function transfer(address _to, uint _value)
    returns (bool success);
  
  // BK Ok
  function transferFrom(address _from, address _to, uint _value) 
    returns (bool success);
  
  // BK Ok
  function approve(address _spender, uint _value) 
    returns (bool success);
  
  // BK Ok - Constant function
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

// BK Ok
contract ERC20Token is ERC20Interface, Owned {
  
  // BK Ok
  using SafeMath3 for uint;

  // BK Next 2 Ok
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  // Functions ------------------------

  /* Get the account balance for an address */

  // BK Ok - Constant function
  function balanceOf(address _owner) constant 
    returns (uint balance)
  {
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  // BK Ok
  function transfer(address _to, uint _amount) 
    returns (bool success)
  {
    // amount sent cannot exceed balance
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
  function approve(address _spender, uint _amount) 
    returns (bool success)
  {
    // before changing the approve amount for an address, its allowance
    // must be reset to 0 to mitigate the race condition described here:
    // cf https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    // BK Ok
    require( _amount == 0 || allowed[msg.sender][_spender] == 0 );
      
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
  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool success) 
  {
    // balance checks
    // BK Ok
    require( balances[_from] >= _amount );
    // BK Ok
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

  // BK Ok - Constant function
  function allowance(address _owner, address _spender) constant 
    returns (uint remaining)
  {
    // BK Ok
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
  
  // BK Ok
  uint constant E6  = 10**6;
  uint constant E18 = 10**18;

  /* Basic token data */

  // BK Next 3 Ok
  string public constant name = "Gizer Gaming Token";
  string public constant symbol = "GZR";
  uint8  public constant decimals = 6;

  /* Wallet address - initially set to owner at deployment */
  
  // BK Ok
  address public wallet;

  /* Gizer redemption wallet - to redeem GZR tokens for Gizer gaming items */
  
  // BK Ok
  address public redemptionWallet;

  /* Token volumes */

  // BK Next block Ok
  uint public constant TOKEN_SUPPLY_TOTAL   = 100 * E6 * E6; // 100 mm tokens
  uint public constant TOKEN_SUPPLY_TEAM    =  15 * E6 * E6; //  15 mm tokens
  uint public constant TOKEN_SUPPLY_RESERVE =  15 * E6 * E6; //  15 mm tokens
  uint public constant TOKEN_SUPPLY_CROWD   =  70 * E6 * E6; //  70 mm tokens

  /* General crowdsale parameters */  
  
  // BK Next block Ok
  uint public constant MIN_CONTRIBUTION = E18 / 100; // 0.01 Ether
  uint public constant MAX_CONTRIBUTION = 3333 * E18; // 3,333 Ether
  uint public constant LOCKUP_PERIOD = 180 days;
  uint public constant CLAWBACK_PERIOD = 180 days;

  /* Private sale */

  // BK Ok
  uint public constant PRIVATE_SALE_MAX_ETHER = 1000 * E18; // 1,000 Ether
  
  /* Presale parameters */
  
  // BK Ok - new Date(1508504400 * 1000).toUTCString() => "Fri, 20 Oct 2017 13:00:00 UTC"
  uint public constant DATE_PRESALE_START = 1508504400; // 20-Oct-2017 13:00 UTC
  // BK Ok - new Date(1509368400 * 1000).toUTCString() => "Mon, 30 Oct 2017 13:00:00 UTC"
  uint public constant DATE_PRESALE_END   = 1509368400; // 30-Oct-2017 13:00 UTC
  
  // BK Next block Ok
  uint public constant TOKETH_PRESALE_ONE   = 1150 * E6; // presale wave 1 (1-100)
  uint public constant TOKETH_PRESALE_TWO   = 1100 * E6; // presale wave 2 (101-500)
  uint public constant TOKETH_PRESALE_THREE = 1075 * E6; // presale - others
  
  // BK Next block Ok
  uint public constant CUTOFF_PRESALE_ONE = 100; // last contributor wave 1
  uint public constant CUTOFF_PRESALE_TWO = 500; // last contributor wave 2
  
  // BK Next block Ok
  uint public constant FUNDING_PRESALE_MIN =  333 * E18; //   333 Ether
  uint public constant FUNDING_PRESALE_MAX = 3333 * E18; // 3,333 Ether

  /* ICO parameters (ICO dates can be modified by owner after deployment) */

  // BK NOTE - The following statements are not constants and show be camelCased
  // BK Ok - new Date(1510754400 * 1000).toUTCString() => "Wed, 15 Nov 2017 14:00:00 UTC"
  uint public DATE_ICO_START = 1510754400; // 15-Nov-2017 14:00 UTC
  // BK Ok - new Date(1513346400 * 1000).toUTCString() => "Fri, 15 Dec 2017 14:00:00 UTC"
  uint public DATE_ICO_END   = 1513346400; // 15-Dec-2017 14:00 UTC

  // BK Next block Ok
  uint public constant TOKETH_ICO_ONE = 1050 * E6; // ICO wave 1 (1-500)
  uint public constant TOKETH_ICO_TWO = 1000 * E6; // ICO - others
  
  // BK Ok
  uint public constant CUTOFF_ICO_ONE = 500; // last contributor wave 1

  // BK Ok
  uint public constant ICO_TRIGGER = 100000 * E6; // 100,000 (for declaring ICO end)

  /* Crowdsale variables */

  // BK Ok
  uint public privateEtherReceived = 0; // private sale Ether received by Gizer
                                        // (this is not sent to the contract)

  // BK Ok
  uint public icoEtherReceived = 0; // Ether actually received by the contract
                                    // presale + ICO combined

  // BK Next block Ok
  uint public tokensIssuedTotal = 0;
  uint public tokensIssuedCrowd = 0;
  uint public tokensIssuedTeam = 0;
  uint public tokensIssuedReserve = 0;
  
  // BK Ok
  uint public tokensIssuedPrivate = 0; // is part of tokensIssuedCrowd

  // BK Ok
  uint public lockupEndDate = DATE_ICO_END + LOCKUP_PERIOD; // changes if ICO ends early
                                                   // and resets if DATE_ICO_END changes

  // BK Next block Ok
  bool public icoFinished = false;
  bool public tradeable = false;
  
  // BK Next block Ok
  uint public presaleContributorCount = 0;
  uint public icoContributorCount = 0;

  /* Keep track of Ether received */
  
  // BK Ok
  mapping(address => uint) public balanceEth;
  // BK Ok
  mapping(address => uint) public balanceEthPrivate;
  
  /* Keep track of tokens issued via private sale */
  
  // BK Ok
  mapping(address => uint) public balancesPrivate;

  /* Balances subject to lockup period */
  
  // BK Ok
  mapping(address => uint) balancesLocked;

  /* Whitelist */

  // BK Ok
  address public whitelistWallet;
  // BK Ok
  mapping(address => bool) whitelist;
  
  /* Variables for pre-deployment testing */
  
  // BK Next block Ok
  bool public constant TEST_MODE = false; // set to true for test deployment only
  uint public testTime = DATE_PRESALE_START - 1 days; // only used in test mode

  // Events ---------------------------
  
  // BK Ok - Event
  event WalletUpdated(
    address _newWallet
  );
  
  // BK Ok - Event
  event RedemptionWalletUpdated(
    address _newRedemptionWallet
  );

  // BK Ok - Event
  event IcoDatesUpdated(
    uint _start,
    uint _end
  );

  // BK Ok - Event
  event TokensIssued(
    address indexed _owner,
    uint _tokens, 
    uint _balance, 
    uint _tokensIssuedCrowd,
    bool _isPrivateSale,
    uint _amount
  );
  
  // BK Ok - Event
  event TokensMintedTeam(
    address indexed _owner,
    uint _tokens,
    uint _balance,
    uint _tokensIssuedReserve
  );
  
  // BK Ok - Event
  event TokensMintedReserve(
    address indexed _owner,
    uint _tokens,
    uint _balance,
    uint _tokensIssuedTeam
  );
  
  // BK Ok - Event
  event WhitelistModify(
    address indexed _participant,
    bool _status
  );

  // BK Ok - Event
  event WhitelistWalletChanged(
    address _newWhitelistWallet
  );

  
  // Basic Functions ------------------

  /* Initialize */

  // BK Ok - Constructor
  function GizerToken() {
    // BK Ok
    wallet = msg.sender;
    // BK Ok
    redemptionWallet = wallet;
    // BK Ok
    whitelistWallet = wallet;
  }

  /* Fallback */
  
  // BK Ok
  function () payable
  {
    // BK Ok
    require( whitelist[msg.sender] == true );
    // BK Ok
    buyTokens();
  }

  // Information Functions ------------
  
  /* What time is it? */
  
  // BK Ok - Constant function
  function atNow() constant
    returns (uint)
  {
    // BK Ok
    if (TEST_MODE) return testTime;
    // BK Ok
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

  // BK NOTE - To simplify code, just make `whitelist` public and remove the following function
  // BK Ok - Constant function, unused in this contract, but can be called in the blockchain explorers
  function isWhitelisted(address _participant) constant 
    returns (bool whitelisted)
  {
    // BK NOTE - The next two statements can be simplified to just `return whitelist[_participant];`
    // BK Ok
    if (whitelist[_participant] == true) return true;
    // BK Ok
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

  // BK Ok - Can only be executed by whitelistWallet
  function addToWhitelist(address _participant)
  {
    // BK Ok
    require( msg.sender == whitelistWallet );
    // BK Ok
    whitelist[_participant] = true;
    // BK Ok - Log event
    WhitelistModify(_participant, true);
  }  

  // BK Ok - Can only be executed by whitelistWallet
  function removeFromWhitelist(address _participant)
  {
    // BK Ok
    require( msg.sender == whitelistWallet );
    // BK Ok
    whitelist[_participant] = false;
    // BK Ok
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

  // BK Ok - Only owner can execute
  function setWallet(address _wallet) onlyOwner
  {
    // BK Ok
    require( _wallet != address(0x0) );
    // BK Ok
    wallet = _wallet;
    // BK Ok - Log event
    WalletUpdated(wallet);
  }

  /* Change the redemption wallet address */

  // BK Ok - Only owner can execute
  function setRedemptionWallet(address _wallet) onlyOwner
  {
    // BK Ok
    redemptionWallet = _wallet;
    // BK ERROR - Incorrect wallet
    RedemptionWalletUpdated(wallet);
  }
  
  /* Change the whitelist owner address */

  // BK Ok - Only owner can execute
  function setWhitelistWallet(address _wallet) onlyOwner
  {
    // BK Ok
    whitelistWallet = _wallet;
    // BK ERROR - Incorrect wallet
    WhitelistWalletChanged(wallet);
  }
  
  /* Change ICO dates before ICO start */
  
  // BK Ok - Only owner can execute
  function updateIcoDates(uint _start, uint _end) onlyOwner
  {
    // BK Ok
    require( atNow() < DATE_ICO_START );
    // BK Ok
    require( _start < _end );
    // BK Ok
    require( _end < DATE_PRESALE_END + 180 days ); // sanity check
    // BK Ok - See note re variable (not constant) naming
    DATE_ICO_START = _start;
    // BK Ok - See note re variable (not constant) naming
    DATE_ICO_END = _end;
    // BK Ok
    lockupEndDate = DATE_ICO_END + LOCKUP_PERIOD; // lockup is linked to ICO end date
    // BK Ok
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

  // BK Ok - Only owner can execute
  function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner 
    returns (bool success) 
  {
      // BK Ok
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
```
