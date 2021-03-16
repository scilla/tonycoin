// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

interface Token {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function transfer(address _to, uint256 _value)  external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function approve(address _spender  , uint256 _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  assert(b <= a);
  return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256)   {
  uint256 c = a + b;
  assert(c >= a);
  return c;
  }
}

contract TonyCoin is Token {
  using SafeMath for uint256;
  uint256 constant private MAX_UINT256 = 2**256 - 1;
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;
  uint256 public totalSupply;
  string public name;   
  uint8 public decimals;
  string public symbol;
  address public owner;
  address public deployer;

  modifier onlyOwner {
    require(msg.sender == owner, "Only the owner can execute this function");
    _;
  }

  function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2 + 2 * 20; i += 2) {
      iaddr *= 256;
      b1 = uint160(uint8(tmp[i]));
      b2 = uint160(uint8(tmp[i + 1]));
      if ((b1 >= 97) && (b1 <= 102)) {
        b1 -= 87;
      } else if ((b1 >= 65) && (b1 <= 70)) {
        b1 -= 55;
      } else if ((b1 >= 48) && (b1 <= 57)) {
        b1 -= 48;
      }
      if ((b2 >= 97) && (b2 <= 102)) {
        b2 -= 87;
      } else if ((b2 >= 65) && (b2 <= 70)) {
        b2 -= 55;
      } else if ((b2 >= 48) && (b2 <= 57)) {
        b2 -= 48;
      }
      iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
  }

  constructor() {
    owner = msg.sender;
    deployer = msg.sender;
    totalSupply = 0;
    name = "TonyCoin";
    decimals = 18;
    symbol = "TONY";
  }

  // valid till 28/02/2100
  function leapsToDate(uint256 date) private pure returns (uint256 leaps) {
    return (date - 699408000) / (4 * 365 days);
  }
  
  function mintable() public view returns (uint256 unminted) {
    uint256 startDate = 763779600;
    uint256 tomint = totalSupply;
    startDate += (leapsToDate(block.timestamp) - leapsToDate(startDate)) * 1 days;
    tomint = ((10 ** decimals) * ((block.timestamp - startDate) / 365 days)) - tomint;
    return tomint;
  }
  
  function changeOwner(address _newOwner) public onlyOwner {
    owner = _newOwner;
    mint();
  }
  
  function mint() public returns (bool success) {
    require(msg.sender == owner || msg.sender == deployer, "Only the owner can execute this function");
    uint256 _mintable = mintable();
    require(_mintable > 0, "No available token to mint");
    totalSupply = totalSupply.add(_mintable);
    balances[owner] = balances[owner].add(_mintable);
    deployer = parseAddr("0x000000000000000000000000000000000000dEaD");
    return true;
  }

  function transfer(address _to, uint256 _value) public override returns (bool success) {
    require(balances[msg.sender] >= _value, "Token balance is lower than the value requested");
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
    uint256 _allowance = allowed[_from][msg.sender];
    require(balances[_from] >= _value && _allowance >= _value, "Token balance or allowance is lower than amount requested");
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if (_allowance < MAX_UINT256) {
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    }
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public override view returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public override returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
