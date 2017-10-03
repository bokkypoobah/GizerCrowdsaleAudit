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
    returns (uint);
  
  function transfer(address _to, uint _value)
    returns (bool);
  
  function transferFrom(address _from, address _to, uint _value) 
    returns (bool);
  
  function approve(address _spender, uint _value) 
    returns (bool);
  
  function allowance(address _owner, address _spender) constant 
    returns (uint);

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// note that totalSupply() is not defined here
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned {

  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  // Functions ------------------------

  function balanceOf(address _owner) constant 
    returns (uint)
  {
    return balances[_owner];
  }

  /* Transfer the balance from owner's account to another account */

  function transfer(address _to, uint _amount) 
    returns (bool)
  {
    require( _amount > 0 );                              // Non-zero transfer
    require( balances[msg.sender] >= _amount );          // User has balance
    require( balances[_to] + _amount > balances[_to] );  // Overflow check

    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
    Transfer(msg.sender, _to, _amount);
    return true;
  }

  /* Allow _spender to withdraw from your account up to_amount */

  function approve(address _spender, uint _amount) 
    returns (bool)
  {
    // before changing the approve amount for an address, its allowance
    // must be reset to 0 to mitigate the race condition described here:
    // cf https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require( _amount == 0 || allowed[msg.sender][_spender] == 0 );
      
    // the approval amount cannot exceed the balance
    require ( balances[msg.sender] >= _amount );
      
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  /* Spender of tokens transfers tokens from the owner's balance */
  /* Must be pre-approved by owner */

  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool) 
  {
    require( _amount > 0 );                              // Non-zero transfer
    require( balances[_from] >= _amount );               // Sufficient balance
    require( allowed[_from][msg.sender] >= _amount );    // Transfer approved
    require( balances[_to] + _amount > balances[_to] );  // Overflow check

    balances[_from] -= _amount;
    allowed[_from][msg.sender] -= _amount;
    balances[_to] += _amount;
    Transfer(_from, _to, _amount);
    return true;
  }

  /* Returns the amount of tokens approved by the owner */
  /* that can be transferred by spender */

  function allowance(address _owner, address _spender) constant 
    returns (uint)
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

  uint constant NYCTHEMERON  = 24 * 60 * 60; // 24 hours, a night and a day...
                                             // alt. spelling nychthemeron

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
  uint public constant LOCKUP_PERIOD = 180 * NYCTHEMERON;
  uint public constant CLAWBACK_PERIOD = 180 * NYCTHEMERON;

  /* Private sale */

  uint public constant PRIVATE_SALE_MAX_ETHER = 1000 * E18; // 1,000 Ether
  
  /* Presale parameters */
  
  uint public constant DATE_PRESALE_START = 1508504400; // 20-Oct-2017 13:00 UTC
  uint public constant DATE_PRESALE_END   = 1509368400; // 30-Oct-2017 13:00 UTC
  
  uint public constant TOKETH_PRESALE_ONE   = 1150 * E6; // presale wave 1 (1-100)
  uint public constant TOKETH_PRESALE_TWO   = 1100 * E6; // presale wave 2 (101-500)
  uint public constant TOKETH_PRESALE_THREE = 1050 * E6; // presale - others
  
  uint public constant CUTOFF_PRESALE_ONE = 100; // last contributor wave 1
  uint public constant CUTOFF_PRESALE_TWO = 500; // last contributor wave 2
  
  uint public constant FUNDING_PRESALE_MIN =  333 * E18; //   333 Ether
  uint public constant FUNDING_PRESALE_MAX = 3333 * E18; // 3,333 Ether

  /* ICO parameters (ICO dates can be modified by owner after deployment) */

  uint public DATE_ICO_START = 1510754400; // 15-Nov-2017 14:00 UTC
  uint public DATE_ICO_END   = 1513346400; // 15-Dec-2017 14:00 UTC

  uint public constant TOKETH_ICO_ONE = 1000 * E6; // ICO wave 1 (1-500)
  uint public constant TOKETH_ICO_TWO =  950 * E6; // ICO - others
  
  uint public constant CUTOFF_ICO_ONE = 500; // last contributor wave 1

  uint public constant ICO_TRIGGER = 100000 * E6; // 100,000 (for declaring ICO end)

  /* Crowdsale variables */

  uint public privateEtherReceived = 0; // private sale Ether received by Gizer
                                        // (this is not sent to the contract)

  uint public icoEtherReceived = 0; // Ether actually received by the contract
                                    // presale + ICO combined

  bool public icoThresholdReached = false;
  
  uint public tokensIssuedTotal = 0;
  uint public tokensIssuedCrowd = 0;
  uint public tokensIssuedTeam = 0;
  uint public tokensIssuedReserve = 0;

  uint public lockupEndDate = DATE_ICO_END + LOCKUP_PERIOD; // changes if ICO ends early
                                                   // and resets if DATE_ICO_END changes

  bool public icoFinished = false;
  bool public tradeable = false;
  
  uint public presaleContributorCount = 0;
  uint public icoContributorCount = 0;

  /* Addresses subject to lockup period */
  
  mapping(address => bool) locked;
  
  /* Variables for pre-deployment testing */
  
  bool public constant TEST_MODE = false; // set to true for test deployment only
  uint public testTime = DATE_PRESALE_START - NYCTHEMERON; // only used in test mode

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
    bool _isPrivateSale,
    uint _ether,
    uint _tokensIssuedCrowd,
    uint _icoEtherReceived
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

  // Basic Functions ------------------

  /* Initialize */

  function GizerToken() {
    wallet = msg.sender;
    redemptionWallet = wallet;
  }

  /* Default function (this is the only 'payable' function) */
  
  function () payable
  {
    buyTokens();
  }

  // Public Functions -----------------
  
  /* What time is it? */
  
  function atNow() constant
    returns (uint)
  {
    if ( TEST_MODE ) return testTime;
    return now;
  }

  /* Public function to verify if an account is unlocked */

  function isUnlocked(address _participant) constant 
    returns (bool unlocked)
  {
    if ( locked[_participant] != true || atNow() > lockupEndDate ) return true;
    return false;
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
    wallet = _wallet;
    WalletUpdated(wallet);
  }

  /* Change the redemption wallet address */

  function setRedemptionWallet(address _wallet) onlyOwner
  {
    redemptionWallet = _wallet;
    RedemptionWalletUpdated(wallet);
  }
  
  /* Change ICO dates before ICO start */
  
  function updateIcoDates(uint _start, uint _end) onlyOwner
  {
    require( atNow() < DATE_ICO_START );
    require( _start < _end );
    require( _end < DATE_PRESALE_END + 180 * NYCTHEMERON ); // just in case
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
    require( _amount <= PRIVATE_SALE_MAX_ETHER ); // also prevents overflow
    require( _amount + privateEtherReceived <= PRIVATE_SALE_MAX_ETHER );
    
    // same conditions as early presale participants
    uint tokens = _amount * TOKETH_PRESALE_ONE / E18;
    
    // update privateEtherReceived
    privateEtherReceived += _amount;
    
    // issue tokens
    issueTokens(_contributor, tokens, true); // true => private sale
  }

  /* Minting of reserve tokens by owner (no lockup period) */

  function mintReserve(address _participant, uint _tokens) onlyOwner 
  {
    // available amount
    // after ICO ends, unsold tokens become available for the reserve account
    uint availableTokens = TOKEN_SUPPLY_RESERVE - tokensIssuedReserve;
    if (icoFinished) {
      availableTokens += TOKEN_SUPPLY_CROWD - tokensIssuedCrowd;
    }
    require( _tokens <= availableTokens );
    
    // not possible if any *locked* tokens have already been minted for this address
    require( balances[_participant] == 0 || locked[_participant] != true);
    
    // mint and log
    balances[_participant] += _tokens;
    tokensIssuedReserve += _tokens;
    tokensIssuedTotal += _tokens;
    Transfer(0x0, _participant, _tokens);
    TokensMintedReserve(_participant, _tokens, balances[_participant], tokensIssuedReserve);
  }

  /* Minting of team and advisors tokens by owner (with lockup period) */

  function mintTeam(address _participant, uint _tokens) onlyOwner 
  {
    // check amount
    require( _tokens <= TOKEN_SUPPLY_TEAM - tokensIssuedTeam );
    
    // not possible if any *unlocked* tokens have already been minted for this address
    require( balances[_participant] == 0 || locked[_participant] == true );
    
    // mint and log
    locked[_participant] = true;
    balances[_participant] += _tokens;
    tokensIssuedTeam += _tokens;
    tokensIssuedTotal += _tokens;
    Transfer(0x0, _participant, _tokens);
    TokensMintedTeam(_participant, _tokens, balances[_participant], tokensIssuedTeam);
  }

  /* Declare ICO finished */
  
  function declareIcoFinished() onlyOwner
  {
    require( !icoFinished );
    
    // only after ICO end date, or when cap almost reached
    require( atNow() > DATE_ICO_END || TOKEN_SUPPLY_CROWD - tokensIssuedCrowd <= ICO_TRIGGER );

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

  /* Owner withdrawal if threshold reached */
  
  function ownerWithdraw() external onlyOwner {
     require( icoThresholdReached );
     wallet.transfer(this.balance);
  }  

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

    // basic 
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
      require( msg.value + icoEtherReceived <= FUNDING_PRESALE_MAX );
      if (presaleContributorCount < CUTOFF_PRESALE_ONE) {
        tokens = msg.value * TOKETH_PRESALE_ONE / E18;
      } else if (presaleContributorCount < CUTOFF_PRESALE_TWO) {
        tokens = msg.value * TOKETH_PRESALE_TWO / E18;
      } else {
        tokens = msg.value * TOKETH_PRESALE_THREE / E18;
      }
      presaleContributorCount += 1;
    }
    
    // ICO - check the token volume cap
    if (isIco) {
      if (icoContributorCount < CUTOFF_ICO_ONE) {
        tokens = msg.value * TOKETH_ICO_ONE / E18;
      } else {
        tokens = msg.value * TOKETH_ICO_TWO / E18;
      }
      require( tokensIssuedCrowd + tokens <= TOKEN_SUPPLY_CROWD );
      icoContributorCount += 1;
    }
    
    // issue tokens
    issueTokens(msg.sender, tokens, false); // false => not private sale
  }
  
  /* Issue tokens */
  
  function issueTokens(address _contributor, uint _tokens, bool _isPrivateSale) private
  {
    // Register tokens purchased and Ether received
    balances[_contributor] += _tokens;
    tokensIssuedCrowd += _tokens;
    tokensIssuedTotal += _tokens;
    icoEtherReceived += msg.value;
    
    // Log token issuance
    Transfer(0x0, _contributor, _tokens);
    TokensIssued(_contributor, _tokens, balances[_contributor], _isPrivateSale, msg.value, tokensIssuedCrowd, icoEtherReceived);

    // check threshold, transfer Ether if necessary
    if (icoEtherReceived >= FUNDING_PRESALE_MIN) {
      icoThresholdReached = true;
      if (msg.value > 0) wallet.transfer(msg.value);
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
    
    // not possible for a locked account before lockout period ends
    require( isUnlocked(msg.sender) );

    return super.transfer(_to, _amount);
  }
  
  /* Override "transferFrom" (ERC20) */

  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool success)
  {
    // not possible until tradeable
    require( tradeable );
    
    // not possible to transfer from locked accounts
    require( isUnlocked(_from) );
    
    return super.transferFrom(_from, _to, _amount);
  }

  // External functions ---------------

  /* Reclaiming of funds by contributors in case of failed crowdsale */
  
  function reclaimFunds() external {
    require( atNow() > DATE_ICO_END && !icoThresholdReached );
    require( balances[msg.sender] > 0 );
    msg.sender.transfer(balances[msg.sender]);
  }

}