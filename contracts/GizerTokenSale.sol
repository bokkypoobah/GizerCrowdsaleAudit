pragma solidity ^0.4.15;

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

  // events -------------------------

  event LogOwnershipTransferProposed(
    address indexed _from,
    address indexed _to
  );

  event LogOwnershipTransferred(
    address indexed _from,
    address indexed _to
  );

  // functions ----------------------

  function Owned()
  {
    owner = msg.sender;
  }

  modifier onlyOwner
  {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) onlyOwner
  {
    require(_newOwner != address(0x0));
    LogOwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership()
  {
    require(msg.sender == newOwner);
    LogOwnershipTransferred(owner, newOwner);
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

  // events -------------------------

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

  // functions ----------------------

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

  // variables ----------------------

  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  // functions ---------------------

  // Get the account balance for an address
  //
  function balanceOf(address _owner) constant 
    returns (uint balance)
  {
    return balances[_owner];
  }

  // Transfer the balance from owner's account to another account
  //
  function transfer(address _to, uint _amount) 
    returns (bool success)
  {
    require( _amount > 0 );                              // Non-zero transfer
    require( balances[msg.sender] >= _amount );          // User has balance
    require( balances[_to] + _amount > balances[_to] );  // Overflow check

    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
    Transfer(msg.sender, _to, _amount);
    return true;
  }

  // Allow _spender to withdraw from your account up to_amount.
  //
  function approve(address _spender, uint _amount) 
    returns (bool success)
  {
    // before changing the approve amount for an address, its allowance
    // must be reset to 0 to mitigate the race condition described here:
    // cf https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require( _amount == 0 || allowed[msg.sender][_spender] == 0 );
      
    // the approval amount cannot exceed the balance
    require (balances[msg.sender] >= _amount);
      
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  // Spender of tokens transfer an amount of tokens from the owner's balance
  // Must be pre-approved by owner
  //
  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool success) 
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

  // Returns the amount of tokens approved by the owner that can be
  // transferred by _spender
  //
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


  // VARIABLES ================================


  // utility variable
  
  uint constant E18 = 10**18;

  // basic token data

  string public constant name = "Gizer Gaming Token";
  string public constant symbol = "GZR";
  uint8 public constant decimals = 18;

  // wallet address (can be reset at any time during ICO)
  
  address public wallet;

  // ICO variables that can be reset before ICO starts

  uint public tokensPerEth = 1103 * E18;
  uint public icoTokenSupply = 44000000 * E18;

  // ICO constants #1

  uint public constant TOTAL_TOKEN_SUPPLY = 100000000 * E18; // 100 million
  uint public constant ICO_TRIGGER = 100000 * E18; // 100,000
  uint public constant MIN_CONTRIBUTION = E18 / 100; // 0.01 Ether
  
  // ICO constants #2 : dates

  // Start - 20-Oct-2017 12:00 UTC (noon)
  // End - 20-Nov-2017 12:00 UTC (noon)
  // as per http://www.unixtimestamp.com
  
  uint public constant START_DATE = 1508500800;
  uint public constant END_DATE = 1511179200;
  uint public constant LOCKUP_PERIOD = 180 * 24 * 3600; // 180 days
  uint public lockupEndDate = END_DATE + LOCKUP_PERIOD; // changes if ICO ends early

  // ICO variables

  uint public icoTokensIssued = 0;
  uint public icoEtherReceived = 0;
  bool public icoFinished = false;
  bool public tradeable = false;

  // Minting
  
  uint public ownerTokensMinted = 0;
  
  // Addresses subject to lockup period
  
  mapping(address => bool) locked;
  

  // EVENTS ===================================

  
  event LogWalletUpdated(
    address newWallet
  );
  
  event LogTokensPerEthUpdated(
    uint newTokensPerEth
  );
  
  event LogIcoTokenSupplyUpdated(
    uint newIcoTokenSupply
  );
  
  event LogTokensBought(
    address indexed buyer,
    uint ethers,
    uint tokens, 
    uint participantTokenBalance, 
    uint newIcoTokensIssued,
    uint newIcoEtherReceived
  );
  
  event LogMinting(
    address indexed participant,
    uint tokens,
    uint newOwnerTokensMinted,
    uint8 isLocked
  );


  // FUNCTIONS ================================
  
  // --------------------------------
  // initialize
  // --------------------------------

  function GizerToken() {
    require(icoTokenSupply < TOTAL_TOKEN_SUPPLY);
    owner = msg.sender;
    wallet = msg.sender;
  }


  // --------------------------------
  // implement totalSupply() ERC20 function
  // --------------------------------
  
  function totalSupply() constant
    returns (uint)
  {
    return TOTAL_TOKEN_SUPPLY;
  }


  // --------------------------------
  // changing ICO parameters
  // --------------------------------
  
  // Owner can change the crowdsale wallet address at any time
  //
  function setWallet(address _wallet) onlyOwner
  {
    wallet = _wallet;
    LogWalletUpdated(wallet);
  }
  
  // (before ICO) Owner can change the number of tokens per ETH for ICO
  //
  function setTokensPerEth(uint _tokensPerEth) onlyOwner
  {
    require(now < START_DATE);
    require(_tokensPerEth > 0);
    tokensPerEth = _tokensPerEth;
    LogTokensPerEthUpdated(tokensPerEth);
  }
      

  // (before ICO) Owner can change the number of available tokens for the ICO
  //
  function setIcoTokenSupply(uint _icoTokenSupply) onlyOwner
  {
    require(now < START_DATE);
    require(_icoTokenSupply < TOTAL_TOKEN_SUPPLY);
    icoTokenSupply = _icoTokenSupply;
    LogIcoTokenSupplyUpdated(icoTokenSupply);
  }


  // --------------------------------
  // Default function
  // --------------------------------
  
  function () payable
  {
    buyTokens();
  }

  // --------------------------------
  // Accept ETH during crowdsale
  // --------------------------------

  function buyTokens() payable
  {
    require(!icoFinished);
    require(now >= START_DATE);
    require(now <= END_DATE);
    require(msg.value >= MIN_CONTRIBUTION);
    
    // get number of tokens
    uint tokens = msg.value * tokensPerEth / E18;
    
    // first check if there is enough capacity
    uint available = icoTokenSupply - icoTokensIssued;
    require (tokens <= available); 

    // ok it's possible to issue tokens
    
    // Add tokens purchased to account's balance and total supply
    balances[msg.sender] += tokens;
    icoTokensIssued += tokens;
    icoEtherReceived += msg.value;

    // Log the issuance of tokens
    Transfer(0x0, msg.sender, tokens);
    
    // Log the token purchase
    LogTokensBought(msg.sender, msg.value, tokens, balances[msg.sender], icoTokensIssued, icoEtherReceived);

    // Transfer the contributed ethers to the crowdsale wallet
    wallet.transfer(msg.value);
  }

  
  // --------------------------------
  // Minting of tokens by owner
  // --------------------------------

  // Tokens remaining available to mint by owner
  //
  function availableToMint() constant
    returns (uint)
  {
    // note that icoTokensIssued <= icoTokenSupply 
    if (icoFinished) {
      return TOTAL_TOKEN_SUPPLY - icoTokensIssued - ownerTokensMinted;
    } else {
      return TOTAL_TOKEN_SUPPLY - icoTokenSupply - ownerTokensMinted;        
    }
  }

  // Minting of tokens by owner (no lockup period)
  //    
  function mint(address _participant, uint _tokens) onlyOwner 
  {
    require( _tokens <= availableToMint() );
    
    // not possible if any *locked* tokens have already been minted for this address
    require( balances[_participant] == 0 || locked[_participant] != true);
    
    balances[_participant] += _tokens;
    ownerTokensMinted += _tokens;
    Transfer(0x0, _participant, _tokens);
    LogMinting(_participant, _tokens, ownerTokensMinted, 0);
  }

  // Minting of tokens by owner (with lockup period)
  //    
  function mintLocked(address _participant, uint _tokens) onlyOwner 
  {
    require( _tokens <= availableToMint() );
    
    // not possible if any *unlocked* tokens have already been minted for this address
    require( balances[_participant] == 0 || locked[_participant] == true);
    
    locked[_participant] = true;
    balances[_participant] += _tokens;
    ownerTokensMinted += _tokens;
    Transfer(0x0, _participant, _tokens);
    LogMinting(_participant, _tokens, ownerTokensMinted, 1);
  }

  // Public function to verify if an account is unlocked 
  //
  function isUnlocked(address _participant) constant 
    returns (bool unlocked)
  {
    if ( locked[_participant] != true || now > lockupEndDate ) return true;
    return false;
  }
  
  // --------------------------------
  // Declare ICO finished
  // --------------------------------
  
  function declareIcoFinished() onlyOwner
  {
    // only after ICO end date, or when cap almost reached
    require( now > END_DATE || icoTokenSupply - icoTokensIssued <= ICO_TRIGGER );

    // ICO is declared finished
    icoFinished = true;
    
    // move end of lockup period back if necessary
    if (now < END_DATE) lockupEndDate = now + LOCKUP_PERIOD;
  }

  // --------------------------------
  // Make tokens tradeable
  // --------------------------------
  
  function makeTradeable() onlyOwner
  {
    // the token can only be made tradeable after ICO finishes
    require(icoFinished);
    tradeable = true;
  }

  // --------------------------------
  // Transfers
  // --------------------------------

  function transfer(address _to, uint _amount) 
    returns (bool success)
  {
    // cannot transfer out until tradeable, except for owner
    require(tradeable || msg.sender == owner);
    
    // not possible for a locked account before lockout period ends
    require( isUnlocked(msg.sender) );

    return super.transfer(_to, _amount);
  }

  function transferFrom(address _from, address _to, uint _amount) 
    returns (bool success)
  {
    // not possible until tradeable
    require(tradeable);
    
    // not possible for locked accounts before end of lockout period
    require( isUnlocked(msg.sender) );
    
    return super.transferFrom(_from, _to, _amount);
  }

  // --------------------------------
  // Varia
  // --------------------------------
  
  // Transfer out any accidentally sent ERC20 tokens
  function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner 
    returns (bool success) 
  {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

}