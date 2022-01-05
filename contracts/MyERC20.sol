// contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces.sol";

// Token should have ERC20 standard and thus inherits from ERC20Interface
contract MyERC20 is ERC20Interface {
    // openzeppelin's safemath library seems unnessecary for Solidity >=0.8
    // using SafeMath for uint256;

    // declare variabls name and symbol (abbrv.) of the token
    string private _name = "MyToken";
    string private _symbol = "MTN";

    uint8 private _decimals = 18;
    uint256 private _totalSupply = 10000000000000000000;

    // mapping (hash table) adresses and their balances
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;

    // initializes contract and sets name, symbol, decimals
    // constructor (string memory name_, string memory symbol_) {
    constructor () {
        // _name = name_;
        // _symbol = symbol_;
        // _decimals = 18;
        _balanceOf[msg.sender] = _totalSupply;
    }

    /* 
    We overload/implement the functions declared in the interface
    */

    //function modifier "view" since the state of the blockchain is not changed  
    function name() public view returns (string memory){
        return _name;
    }

    function symbol() external view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint8){
        return _decimals;
    }

    function totalSupply() public view returns (uint256){
        return (_totalSupply);
    }

    function balanceOf(address _tokenOwner) public view returns (uint256){
        return _balanceOf[_tokenOwner];
    }    

    function allowance(
        address _tokenOwner, address _spender) public view returns (uint256){

        return _allowance[_tokenOwner][_spender];
    }

    function transfer(address _recipient, uint _amount) public returns (bool){
        // we require that the sender has sufficient funds
        require(_balanceOf[msg.sender] >= _amount);
        // we require that the sender's and reciepent's address 
        // are not the zero address
        require(_recipient != address(0));
        require(msg.sender != address(0));

        // using safemath
        //_balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_amount);
        //_balanceOf[_recipient] = _balanceOf[_recipient].add(_amount);
           
        // without using safemath
        _balanceOf[msg.sender] -= _amount;
        _balanceOf[_recipient] += _amount; 
        

        // we emit a upon success signal
        emit Transfer(msg.sender, _recipient, _amount);
        /* 
        if everything goes well (i.e. the sender has sufficient funds) 
        we return true
        */
        return true;
    }

    /*     
    Approves the spender to transfer the specified 
    funds from the owners wallet 
    */
    function approve(
        address _spender, uint _amount) public returns (bool){

        require(_spender != address(0));
        require(msg.sender != address(0));

        //we set the allowance of the specified amount
        _allowance[msg.sender][_spender] = _amount;
 
        emit Approval(msg.sender,_spender,_amount);

        return true;
    }

    /*     
    This code is essentially similar to that of transfer(...).
    We could use some refactoring here and implement a private method 
    _transfer(...) used by both methods 
    */
    function transferFrom(
        address _spender, address _recipient, uint _amount) public 
        returns (bool){

        require(_balanceOf[_spender] >= _amount);
        require(_spender != address(0));
        require(_recipient != address(0));
        
        // using safemath
        // _balanceOf[_spender] = _balanceOf[_spender].sub(_amount);
        // _balanceOf[_recipient] = _balanceOf[_recipient].add(_amount);  

        // without using safemath
        _balanceOf[_spender] -= _amount;
        _balanceOf[_recipient] += _amount;       
        
        return true;
    }

    function _mint(address _recipient, uint256 _amount) internal {
        require(_recipient != address(0));
        _totalSupply += _amount;
        _balanceOf[_recipient] += _amount;
        emit Transfer(address(0), _recipient, _amount);
    }

    function _burn(address _recipient, uint256 _amount) internal {
        require(_recipient != address(0));
        require(_amount <= _balanceOf[_recipient]);

        _totalSupply -= _amount;
        _balanceOf[_recipient] -= _amount;
        emit Transfer(_recipient, address(0), _amount);
    }
}